# save-to-github

A Claude Code slash command that saves projects to GitHub with automatic PII detection, sanitization, and README generation.

## Features

- **Automatic PII Detection**: Scans for personal paths, emails, API keys, secrets, and `.env` files before pushing
- **Smart Sanitization**: Replaces sensitive data with placeholders (personal paths, work emails, API keys)
- **Template vs Showcase Modes**: Choose whether to sanitize for others to fork (template) or share as-is (showcase)
- **Auto-generated README**: Creates a README based on project type and intention

## Installation

Copy these files to your Claude Code configuration directory:

```bash
# Copy the slash command
cp commands/save-to-github.md ~/.claude/commands/

# Copy the scripts
cp scripts/*.sh ~/.claude/scripts/

# Make scripts executable
chmod +x ~/.claude/scripts/*.sh
```

## Usage

In Claude Code, simply run:

```
/save-to-github
```

The command will:
1. Analyze your project
2. Ask you a few questions (repo name, mode, intention, visibility)
3. Scan for PII and ask to sanitize if found
4. Generate a README
5. Create the GitHub repository and push

## Files

| File | Description |
|------|-------------|
| `commands/save-to-github.md` | The slash command definition |
| `scripts/sanitize-for-template.sh` | PII detection and sanitization script |
| `scripts/generate-readme.sh` | README generator based on project type |
| `scripts/save-to-github.sh` | GitHub repository creation script |

## Customization

### Adding Your Own PII Patterns

Edit `scripts/sanitize-for-template.sh` and update:

```bash
# Known usernames to scrub (add your username)
USERNAMES="your-username"

# Known work emails to scrub (add your work email)
WORK_EMAILS="you@yourcompany.com"
```

### PII Detection Modes

The sanitization script supports multiple modes:

```bash
# Preview what would be sanitized (full template mode)
./sanitize-for-template.sh /path/to/project --preview

# Preview PII only (no password/general email scrubbing)
./sanitize-for-template.sh /path/to/project --pii-preview

# Apply full sanitization (template mode)
./sanitize-for-template.sh /path/to/project

# Apply PII-only sanitization (showcase mode)
./sanitize-for-template.sh /path/to/project --pii-only
```

## What Gets Detected

| Pattern | Action |
|---------|--------|
| `/Users/username/...` paths | Replaced with `/path/to/your` |
| Work emails (configured) | Replaced with `your-email@example.com` |
| API keys (`sk-...`, `sk-ant-...`) | Replaced with `YOUR_API_KEY` |
| `SECRET=value` patterns | Value replaced with `YOUR_SECRET` |
| `.env` files | Deleted and added to `.gitignore` |

## Requirements

- [Claude Code](https://claude.com/claude-code) CLI
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated

---

Generated with [Claude Code](https://claude.com/claude-code)
