#!/bin/bash

# Generates README.md based on project mode and intention
# Usage: generate-readme.sh <project_path> <project_name> <mode> <intention> [detail]
# mode: template | showcase
# intention: learning | personal | shareable | portfolio | experiment

PROJECT_PATH="$1"
PROJECT_NAME="$2"
MODE="$3"           # template or showcase
INTENTION="$4"      # learning, personal, shareable, portfolio, experiment
DETAIL="${5:-}"     # optional additional context

# Input validation - check required parameters
if [ -z "$PROJECT_PATH" ] || [ -z "$PROJECT_NAME" ] || [ -z "$MODE" ] || [ -z "$INTENTION" ]; then
    echo "Error: Missing required parameters" >&2
    echo "" >&2
    echo "Usage: generate-readme.sh <project_path> <project_name> <mode> <intention> [detail]" >&2
    echo "" >&2
    echo "  project_path: Path to the project directory" >&2
    echo "  project_name: Name of the project" >&2
    echo "  mode:         template | showcase" >&2
    echo "  intention:    learning | personal | shareable | portfolio | experiment" >&2
    echo "  detail:       (optional) Additional context or description" >&2
    exit 1
fi

# Mode validation - ensure mode is valid
if [ "$MODE" != "template" ] && [ "$MODE" != "showcase" ]; then
    echo "Error: Invalid mode '$MODE'. Must be 'template' or 'showcase'" >&2
    exit 1
fi

# Don't overwrite existing README unless it's auto-generated
if [ -f "$PROJECT_PATH/README.md" ]; then
    if ! grep -qF "Generated with" "$PROJECT_PATH/README.md"; then
        echo "README.md already exists and appears to be custom. Skipping."
        exit 0
    fi
fi

# Find main files for listing
PYTHON_FILES=$(find "$PROJECT_PATH" -maxdepth 2 -name "*.py" -type f 2>/dev/null | head -5)
JS_FILES=$(find "$PROJECT_PATH" -maxdepth 2 \( -name "*.js" -o -name "*.ts" \) -type f 2>/dev/null | head -5)
SHELL_FILES=$(find "$PROJECT_PATH" -maxdepth 2 -name "*.sh" -type f 2>/dev/null | head -5)

# Build file list
FILES_LIST=""
for file in $PYTHON_FILES $JS_FILES $SHELL_FILES; do
    [ -n "$file" ] && FILES_LIST="$FILES_LIST\n- \`$(basename "$file")\`"
done
[ -z "$FILES_LIST" ] && FILES_LIST="- See project files"

# Mode-specific content
if [ "$MODE" = "template" ]; then
    MODE_HEADER="## How to Use This Template

1. Fork this repository
2. Clone your fork locally
3. Customize the configuration (see Customization section)
4. Make it your own!

## Customization

- Update configuration values marked with \`YOUR_*\` placeholders
- Modify the logic to fit your specific use case
- Add your own features and enhancements"

    MODE_INTRO="A template for building your own"
else
    MODE_HEADER="## About This Project

Built with Claude Code."

    MODE_INTRO="Here's what I built"
fi

# Intention-specific content
case "$INTENTION" in
    learning)
        INTENTION_SECTION="## What I Learned

This project was built to learn and practice new skills.

### Skills Practiced
- [Add skills you practiced]

### Resources Used
- [Add resources that helped]"
        ;;
    personal)
        INTENTION_SECTION="## The Problem It Solves

This tool was built to solve a specific personal need.

### How I Use It
- [Describe your workflow]"
        ;;
    shareable)
        INTENTION_SECTION="## Installation

\`\`\`bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/$PROJECT_NAME.git
cd $PROJECT_NAME

# Install dependencies (if applicable)
pip install -r requirements.txt  # or npm install
\`\`\`

## Usage

\`\`\`bash
# Add usage examples here
python main.py --help
\`\`\`

## Configuration

See the configuration file for available options."
        ;;
    portfolio)
        INTENTION_SECTION="## Technical Highlights

### Architecture Decisions
- [Describe key technical decisions]

### Challenges Overcome
- [Describe challenges and solutions]

### Technologies Used
- [List key technologies]"
        ;;
    experiment)
        INTENTION_SECTION="## The Experiment

### Hypothesis
[What were you testing or exploring?]

### Findings
[What did you discover?]

### Limitations
This is an experimental project and may not be production-ready."
        ;;
    *)
        INTENTION_SECTION=""
        ;;
esac

# Add user's detail if provided
DETAIL_SECTION=""
if [ -n "$DETAIL" ]; then
    DETAIL_SECTION="

$DETAIL"
fi

# Generate README
cat > "$PROJECT_PATH/README.md" << EOF
# $PROJECT_NAME

$MODE_INTRO$DETAIL_SECTION

$MODE_HEADER

$INTENTION_SECTION

## Files

$(echo -e "$FILES_LIST")

## Requirements

- Python 3.x (if applicable)
- See requirements.txt for dependencies (if present)

---

*Generated with [Claude Code](https://claude.com/code)*
EOF

echo "README created at $PROJECT_PATH/README.md"
