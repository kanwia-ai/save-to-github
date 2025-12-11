---
description: Save current project to GitHub as its own repository
---

# Save to GitHub

I'll help you save this project to GitHub with a personalized README.

## Step 1: Project Analysis

First, let me analyze your project to understand what we're working with.

**Action:** Run the following bash commands to analyze the project:

```bash
CURRENT_DIR=$(pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")
SUGGESTED_REPO_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | tr ' ' '-')

echo "Project: $PROJECT_NAME"
echo "Location: $CURRENT_DIR"
echo "Suggested repo name: $SUGGESTED_REPO_NAME"
echo ""
echo "Project structure:"
ls -la "$CURRENT_DIR" | head -20
echo ""

# Check for README
if [ -f "$CURRENT_DIR/README.md" ]; then
    echo "Existing README found:"
    if grep -qF "Generated with" "$CURRENT_DIR/README.md"; then
        echo "  (Auto-generated - will be replaced)"
    else
        echo "  (Custom - will be preserved)"
    fi
fi
```

## Step 2: Gather Information

Now I need to ask you a few questions to configure your repository properly.

**Action:** Use the AskUserQuestion tool to ask these 4 questions:

### Question 1: Repository Name
```json
{
  "questions": [{
    "question": "What should this repository be called?",
    "header": "Repo name",
    "multiSelect": false,
    "options": [
      {
        "label": "Use folder name ([actual-suggested-name])",
        "description": "Keep it simple with the current folder name"
      },
      {
        "label": "Custom name",
        "description": "I'll provide a different name"
      }
    ]
  }]
}
```

**Important:** Before calling AskUserQuestion, you must replace `[actual-suggested-name]` in the label text with the real value of SUGGESTED_REPO_NAME that you obtained in Step 1. For example, if SUGGESTED_REPO_NAME is "my-project", the label should read "Use folder name (my-project)". DO NOT pass the placeholder text to AskUserQuestion - substitute the actual value first. If user selects "Custom name", the "Other" text input will contain their custom repo name.

### Question 2: Project Type (Template vs Showcase)
```json
{
  "questions": [{
    "question": "How do you want to share this project?",
    "header": "Project type",
    "multiSelect": false,
    "options": [
      {
        "label": "Template",
        "description": "For others to fork and customize - will sanitize personal data"
      },
      {
        "label": "Showcase",
        "description": "Share exactly as you built it"
      }
    ]
  }]
}
```

### Question 3: Project Intention
```json
{
  "questions": [{
    "question": "What was your goal in building this?",
    "header": "Intention",
    "multiSelect": false,
    "options": [
      {
        "label": "Learning",
        "description": "Built to learn a new skill or concept"
      },
      {
        "label": "Personal Tool",
        "description": "Solves a specific problem for yourself"
      },
      {
        "label": "Shareable Tool",
        "description": "Built for others to use"
      },
      {
        "label": "Portfolio",
        "description": "Demonstrates your skills"
      },
      {
        "label": "Experiment",
        "description": "Testing an idea or exploring a concept"
      }
    ]
  }]
}
```

**Note:** After this question, ask the user: "Any additional context you'd like to add to the README? (optional)" and store their response as DETAIL variable.

### Question 4: Repository Visibility
```json
{
  "questions": [{
    "question": "Should this repository be public or private?",
    "header": "Visibility",
    "multiSelect": false,
    "options": [
      {
        "label": "Public",
        "description": "Anyone can see this repository"
      },
      {
        "label": "Private",
        "description": "Only you can see this repository"
      }
    ]
  }]
}
```

## Step 3: Process Responses

**Action:** Store the user's answers in variables:
- `REPO_NAME`: from Question 1 (use suggested name or custom name from "Other" field)
- `MODE`: "template" or "showcase" (lowercase) from Question 2
- `INTENTION`: "learning", "personal", "shareable", "portfolio", or "experiment" (lowercase) from Question 3
- `DETAIL`: optional text from follow-up question after Question 3
- `VISIBILITY`: "public" or "private" (lowercase) from Question 4

## Step 4: PII Scan (ALWAYS runs)

**CRITICAL: This step runs for ALL repos (both template and showcase mode) to prevent accidental PII exposure.**

### Step 4a: Run PII Preview

**Action:** Always run the PII scan first to check for sensitive data:

```bash
~/.claude/scripts/sanitize-for-template.sh "$CURRENT_DIR" --pii-preview
```

### Step 4b: Handle PII Results

**If PII is found:**
- Show the user what was detected
- Inform them: "I found potential PII (personal paths, emails, secrets, .env files) that should be removed before pushing to GitHub."
- Ask: "Should I automatically scrub this PII? (This will replace personal paths, emails, and secrets with placeholders, and delete any .env files)"

**If user confirms PII scrub:**
```bash
~/.claude/scripts/sanitize-for-template.sh "$CURRENT_DIR" --pii-only
```

**If user declines PII scrub:**
Present these options:
- **Option 1: Continue anyway** - User accepts the risk of PII in their repo
- **Option 2: Manual review** - User wants to review and fix manually, exit the command
- **Option 3: Cancel** - Stop the save-to-github command entirely

### Step 4c: Template Mode Additional Sanitization (if applicable)

**Condition:** If MODE is "template" AND user wants full sanitization (not just PII):

**Action:** Show full sanitization preview:

```bash
~/.claude/scripts/sanitize-for-template.sh "$CURRENT_DIR" --preview
```

After showing the preview, ask the user: "Template mode includes additional sanitization (replacing all emails, passwords, etc.). Do you want to apply full template sanitization?"

**If user confirms full sanitization:**

```bash
~/.claude/scripts/sanitize-for-template.sh "$CURRENT_DIR"
```

**If user declines:**
- Continue with showcase mode behavior (PII-only scrub was already applied in Step 4b)
- Inform user their personal data has been scrubbed but general emails/passwords remain

## Step 5: Generate README

**Action:** Generate the README with collected parameters:

```bash
~/.claude/scripts/generate-readme.sh "$CURRENT_DIR" "$REPO_NAME" "$MODE" "$INTENTION" "$DETAIL"
```

**Note:** If DETAIL is empty, you can omit it from the command (it's optional).

Show the user: "README generated! Here's a preview:" and display the first 30 lines of the README.

```bash
head -30 "$CURRENT_DIR/README.md"
```

## Step 6: Create Repository and Push

**Action:** Create the GitHub repository and push the code:

```bash
# Create a description for the repo
DESCRIPTION="Created with Claude Code save-to-github command"

# Run the save script
~/.claude/scripts/save-to-github.sh "$CURRENT_DIR" "$REPO_NAME" "$VISIBILITY" "$DESCRIPTION"
```

## Step 7: Completion

**Success!** Your project is now on GitHub.

**Action:** Display the final repository information:

```bash
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null)
echo ""
echo "Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "Visibility: $VISIBILITY"
echo "Mode: $MODE"
echo ""
echo "Next steps:"
echo "- Visit your repository to verify everything looks good"
echo "- Edit the README to fill in any [Add...] placeholders"
if [ "$MODE" = "template" ]; then
    echo "- Review sanitized files to ensure no sensitive data remains"
    echo "- Update YOUR_* placeholders with instructions for users"
fi
```

## Implementation Notes

**For Claude:** When implementing this command:

1. **Execute Step 1** first - get project info and suggested repo name
2. **Execute Step 2** - use AskUserQuestion tool exactly as specified for all 4 questions
3. **Parse answers** - extract values from the AskUserQuestion responses
4. **ALWAYS run PII scan** - run `--pii-preview` for ALL repos, not just templates
5. **Handle PII results** - if PII found, ask user to confirm scrubbing before proceeding
6. **Handle template mode** - if user chose "Template", run additional full sanitization
7. **Generate README** - call generate-readme.sh with all collected parameters
8. **Create repo** - call save-to-github.sh to finalize
9. **Confirm completion** - show the repository URL and next steps

**CRITICAL:** Never skip the PII scan step. This protects users from accidentally exposing:
- Personal usernames and home directory paths
- Work email addresses
- API keys (OpenAI, Anthropic, etc.)
- .env files with secrets
- Password values

**Variable Mapping:**
- Mode "Template" → mode parameter: "template"
- Mode "Showcase" → mode parameter: "showcase"
- Intention "Learning" → intention parameter: "learning"
- Intention "Personal Tool" → intention parameter: "personal"
- Intention "Shareable Tool" → intention parameter: "shareable"
- Intention "Portfolio" → intention parameter: "portfolio"
- Intention "Experiment" → intention parameter: "experiment"
- Visibility "Public" → visibility parameter: "public"
- Visibility "Private" → visibility parameter: "private"

**Error Handling:**
- If any script fails, show the error and stop the process
- If README already exists and is custom, inform the user it will be preserved
- If repo already exists on GitHub, the save script will prompt for confirmation
