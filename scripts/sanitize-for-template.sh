#!/bin/bash

# Sanitizes a project directory for PII and sensitive data
# Replaces sensitive data and personal content with placeholders
# Returns a preview of changes without modifying files when --preview flag is used
#
# Modes:
#   --preview    Show what would be changed without modifying
#   --pii-only   Only scrub PII (emails, usernames, paths) - used for all repos
#   (no flag)    Full sanitization for template mode

set -e

PROJECT_PATH="$1"
MODE="${2:-}"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# File extensions to process
EXTENSIONS="py sh js ts json yaml yml md txt cfg ini conf env toml"

# Known usernames to scrub (add more as needed)
USERNAMES="kyraatekwana"

# Known work emails to scrub
WORK_EMAILS="your-email@example.com"

check_env_files() {
    # Check for .env files that should be removed/gitignored
    local env_files=$(find "$PROJECT_PATH" -name ".env" -o -name "*.env" -o -name ".env.*" 2>/dev/null | grep -v node_modules | grep -v .git)
    if [ -n "$env_files" ]; then
        echo -e "${RED}=== WARNING: .env files found ===${NC}"
        echo "$env_files"
        echo "  -> These should be deleted and added to .gitignore"
        echo ""
        return 0
    fi
    return 1
}

preview_changes() {
    local pii_only="${1:-false}"

    if [ "$pii_only" = "true" ]; then
        echo -e "${YELLOW}=== PII Scan Preview ===${NC}"
    else
        echo -e "${YELLOW}=== Sanitization Preview ===${NC}"
    fi
    echo ""

    local found_any=false

    # Check for .env files first
    if check_env_files; then
        found_any=true
    fi

    for ext in $EXTENSIONS; do
        while IFS= read -r -d '' file; do
            # Check for personal paths (any /Users/username pattern)
            for username in $USERNAMES; do
                if grep -q "/Users/$username" "$file" 2>/dev/null; then
                    echo -e "${GREEN}$file${NC}"
                    grep -n "/Users/$username" "$file" | head -5
                    echo "  -> Will replace with: \$HOME or /path/to/your"
                    echo ""
                    found_any=true
                fi
            done

            # Check for known work emails
            for email in $WORK_EMAILS; do
                if grep -q "$email" "$file" 2>/dev/null; then
                    echo -e "${GREEN}$file${NC}"
                    grep -n "$email" "$file" | head -3
                    echo "  -> Will replace with: your-email@example.com"
                    echo ""
                    found_any=true
                fi
            done

            # Check for potential API keys (OpenAI, Anthropic, etc.)
            if grep -qE '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9-]{20,}|ANTHROPIC_API_KEY|OPENAI_API_KEY)' "$file" 2>/dev/null; then
                echo -e "${GREEN}$file${NC}"
                grep -nE '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9-]{20,}|ANTHROPIC_API_KEY|OPENAI_API_KEY)' "$file" | head -3
                echo "  -> Will replace with: YOUR_API_KEY"
                echo ""
                found_any=true
            fi

            # Check for SECRET= patterns in any file
            if grep -qE '^[A-Z_]*SECRET[A-Z_]*=' "$file" 2>/dev/null; then
                echo -e "${GREEN}$file${NC}"
                grep -nE '^[A-Z_]*SECRET[A-Z_]*=' "$file" | head -3
                echo "  -> Will replace value with: YOUR_SECRET"
                echo ""
                found_any=true
            fi

            # Only check these in full sanitization mode (not pii-only)
            if [ "$pii_only" = "false" ]; then
                # Check for email addresses (excluding example.com)
                if grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null; then
                    matches=$(grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" | grep -v 'example.com' | grep -v 'noreply@' | head -3)
                    if [ -n "$matches" ]; then
                        echo -e "${GREEN}$file${NC}"
                        echo "$matches" | while read -r email; do
                            echo "  Found: $email"
                        done
                        echo "  -> Will replace with: your-email@example.com"
                        echo ""
                        found_any=true
                    fi
                fi

                # Check for password patterns
                if grep -qiE 'password[[:space:]]*=[[:space:]]*["\x27]' "$file" 2>/dev/null; then
                    echo -e "${GREEN}$file${NC}"
                    grep -niE 'password[[:space:]]*=[[:space:]]*["\x27]' "$file" | head -3
                    echo "  -> Will replace with: password = \"YOUR_PASSWORD\""
                    echo ""
                    found_any=true
                fi
            fi
        done < <(find "$PROJECT_PATH" -name "*.$ext" -type f -print0 2>/dev/null)
    done

    if [ "$found_any" = false ]; then
        echo "No sensitive data patterns found."
    fi

    # Return whether we found anything
    [ "$found_any" = true ]
}

apply_sanitization() {
    local pii_only="${1:-false}"

    if [ "$pii_only" = "true" ]; then
        echo -e "${YELLOW}=== Applying PII Scrub ===${NC}"
    else
        echo -e "${YELLOW}=== Applying Sanitization ===${NC}"
    fi

    # Handle .env files - delete them and ensure .gitignore exists
    local env_files=$(find "$PROJECT_PATH" -name ".env" -o -name "*.env" -o -name ".env.*" 2>/dev/null | grep -v node_modules | grep -v .git)
    if [ -n "$env_files" ]; then
        echo -e "${RED}Removing .env files:${NC}"
        echo "$env_files" | while read -r env_file; do
            rm -f "$env_file"
            echo "  Deleted: $env_file"
        done

        # Ensure .gitignore has .env entries
        if [ ! -f "$PROJECT_PATH/.gitignore" ]; then
            echo "# Environment files" > "$PROJECT_PATH/.gitignore"
            echo ".env" >> "$PROJECT_PATH/.gitignore"
            echo "*.env" >> "$PROJECT_PATH/.gitignore"
            echo ".env.*" >> "$PROJECT_PATH/.gitignore"
            echo "Created .gitignore with .env entries"
        elif ! grep -q "^\.env$" "$PROJECT_PATH/.gitignore" 2>/dev/null; then
            echo "" >> "$PROJECT_PATH/.gitignore"
            echo "# Environment files" >> "$PROJECT_PATH/.gitignore"
            echo ".env" >> "$PROJECT_PATH/.gitignore"
            echo "*.env" >> "$PROJECT_PATH/.gitignore"
            echo ".env.*" >> "$PROJECT_PATH/.gitignore"
            echo "Added .env entries to .gitignore"
        fi
    fi

    for ext in $EXTENSIONS; do
        while IFS= read -r -d '' file; do
            local modified=false

            # Replace personal paths for all known usernames
            for username in $USERNAMES; do
                if grep -q "/Users/$username" "$file" 2>/dev/null; then
                    # Replace paths within quotes (handles spaces in paths)
                    sed -i '' "s|\"/Users/$username/[^\"]*\"|\"/path/to/your\"|g" "$file"
                    sed -i '' "s|'/Users/$username/[^']*'|'/path/to/your'|g" "$file"
                    # Replace unquoted paths (without spaces)
                    sed -i '' "s|/Users/$username/[^\"'[:space:]]*|/path/to/your|g" "$file"
                    # Replace standalone path
                    sed -i '' "s|/Users/$username|/path/to/your|g" "$file"
                    modified=true
                fi
            done

            # Replace known work emails
            for email in $WORK_EMAILS; do
                if grep -q "$email" "$file" 2>/dev/null; then
                    sed -i '' "s|$email|your-email@example.com|g" "$file"
                    modified=true
                fi
            done

            # Replace API keys (OpenAI, Anthropic patterns)
            if grep -qE 'sk-[a-zA-Z0-9]{20,}' "$file" 2>/dev/null; then
                sed -i '' 's/sk-[a-zA-Z0-9]\{20,\}/YOUR_API_KEY/g' "$file"
                modified=true
            fi
            if grep -qE 'sk-ant-[a-zA-Z0-9-]{20,}' "$file" 2>/dev/null; then
                sed -i '' 's/sk-ant-[a-zA-Z0-9-]\{20,\}/YOUR_API_KEY/g' "$file"
                modified=true
            fi

            # Replace SECRET= patterns
            if grep -qE '^[A-Z_]*SECRET[A-Z_]*=.+' "$file" 2>/dev/null; then
                sed -i '' -E 's/^([A-Z_]*SECRET[A-Z_]*)=.+$/\1=YOUR_SECRET/g' "$file"
                modified=true
            fi

            # Only apply these in full sanitization mode (not pii-only)
            if [ "$pii_only" = "false" ]; then
                # Replace emails (excluding example.com domains)
                if grep -qE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" 2>/dev/null; then
                    # Check if there are non-example.com emails to replace
                    if grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$file" | grep -qv 'example.com'; then
                        # Replace common personal email patterns (but not example.com)
                        sed -i '' -E 's/[a-zA-Z0-9._%+-]+@gmail\.com/your-email@example.com/g' "$file"
                        sed -i '' -E 's/[a-zA-Z0-9._%+-]+@yahoo\.com/your-email@example.com/g' "$file"
                        sed -i '' -E 's/[a-zA-Z0-9._%+-]+@hotmail\.com/your-email@example.com/g' "$file"
                        sed -i '' -E 's/[a-zA-Z0-9._%+-]+@outlook\.com/your-email@example.com/g' "$file"
                        modified=true
                    fi
                fi

                # Replace password patterns (case-insensitive)
                if grep -qiE 'password[[:space:]]*=[[:space:]]*["\x27]' "$file" 2>/dev/null; then
                    sed -i '' -E 's/[pP][aA][sS][sS][wW][oO][rR][dD][[:space:]]*=[[:space:]]*"[^"]+"/password = "YOUR_PASSWORD"/g' "$file"
                    sed -i '' -E "s/[pP][aA][sS][sS][wW][oO][rR][dD][[:space:]]*=[[:space:]]*'[^']+'/password = 'YOUR_PASSWORD'/g" "$file"
                    modified=true
                fi
            fi

            if [ "$modified" = true ]; then
                echo "Sanitized: $file"
            fi
        done < <(find "$PROJECT_PATH" -name "*.$ext" -type f -print0 2>/dev/null)
    done

    echo -e "${GREEN}Sanitization complete.${NC}"
}

# Main
if [ -z "$PROJECT_PATH" ]; then
    echo "Usage: sanitize-for-template.sh <project_path> [--preview|--pii-only|--pii-preview]"
    echo ""
    echo "Modes:"
    echo "  --preview      Preview full sanitization (for template mode)"
    echo "  --pii-only     Apply PII scrub only (usernames, emails, paths, secrets)"
    echo "  --pii-preview  Preview PII scrub only"
    echo "  (no flag)      Apply full sanitization (for template mode)"
    exit 1
fi

case "$MODE" in
    "--preview")
        preview_changes "false"
        ;;
    "--pii-preview")
        preview_changes "true"
        ;;
    "--pii-only")
        apply_sanitization "true"
        ;;
    *)
        apply_sanitization "false"
        ;;
esac
