#!/bin/bash

# Creates a new GitHub repository for a project and pushes code
# Called by the save-to-github slash command after gathering user input
# Usage: save-to-github.sh <project_path> <repo_name> <visibility> <description>

set -e

PROJECT_PATH="$1"
REPO_NAME="$2"
VISIBILITY="$3"      # public or private
DESCRIPTION="${4:-}" # optional description

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Validate inputs
if [ -z "$PROJECT_PATH" ] || [ -z "$REPO_NAME" ] || [ -z "$VISIBILITY" ]; then
    echo -e "${RED}Usage: save-to-github.sh <project_path> <repo_name> <visibility> [description]${NC}"
    exit 1
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Get GitHub username
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)
if [ -z "$GITHUB_USER" ]; then
    echo -e "${RED}Error: Could not get GitHub username. Run 'gh auth login' first.${NC}"
    exit 1
fi

echo -e "${BLUE}Creating repository: $REPO_NAME${NC}"

# Check if repo already exists
if gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
    echo -e "${YELLOW}Repository $REPO_NAME already exists!${NC}"
    echo -e "${YELLOW}Do you want to push to the existing repo? This may overwrite content.${NC}"
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Aborted."
        exit 1
    fi
else
    # Create new repository
    VISIBILITY_FLAG="--public"
    [ "$VISIBILITY" = "private" ] && VISIBILITY_FLAG="--private"

    if [ -n "$DESCRIPTION" ]; then
        gh repo create "$REPO_NAME" $VISIBILITY_FLAG --description "$DESCRIPTION"
    else
        gh repo create "$REPO_NAME" $VISIBILITY_FLAG
    fi
    echo -e "${GREEN}Repository created!${NC}"
fi

# Initialize git in project if needed
cd "$PROJECT_PATH"
if [ ! -d ".git" ]; then
    git init
    echo -e "${BLUE}Initialized git repository${NC}"
fi

# Set remote
REPO_URL="https://github.com/$GITHUB_USER/$REPO_NAME.git"
if git remote get-url origin &> /dev/null; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

# Add all files and commit
git add .
if git diff --cached --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    git commit -m "Initial commit

Created with Claude Code save-to-github command"
fi

# Push to GitHub
git branch -M main
git push -u origin main

# Success message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Successfully saved to GitHub!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Repository:${NC} https://github.com/$GITHUB_USER/$REPO_NAME"
echo -e "${BLUE}Visibility:${NC} $VISIBILITY"
echo ""
