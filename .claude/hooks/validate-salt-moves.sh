#!/bin/bash
# Validates Salt file references before moving/renaming files
# Runs on PreToolUse for Bash commands

set -e

# Load input from environment variables
TOOL_INPUT="${TOOL_INPUT:-{}}"
TOOL_NAME="${TOOL_NAME:-unknown}"
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

# Only validate move/rename operations
if [[ ! "$COMMAND" =~ ^(mv|cp|rm|rmdir) ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="$PROJECT_DIR/srv/salt"
PROVISIONING_DIR="$PROJECT_DIR/provisioning"

# Extract filenames from the command
# Handle patterns like: mv "src/file.sls" "new_location/"
SOURCE_FILE=$(echo "$COMMAND" | grep -oP '(?<=mv\s)["\047]?[^"\047\s]+["\047]?' | head -1 | sed 's/["\047]//g')
DEST_FILE=$(echo "$COMMAND" | grep -oP '(?<=mv\s)["\047]?[^"\047\s]+["\047]?' | tail -1 | sed 's/["\047]//g')

# Check if moving Salt state files or provisioning files
if [[ "$SOURCE_FILE" == *.sls ]] || [[ "$SOURCE_FILE" =~ (provisioning|srv/salt) ]]; then

  # Extract the salt:// reference that would break
  # Example: srv/salt/windows/win.sls -> windows.win
  if [[ "$SOURCE_FILE" =~ srv/salt/(.+\.sls)$ ]]; then
    SALT_REF="${BASH_REMATCH[1]%.sls}"
    SALT_REF="${SALT_REF//\//.}"

    # Search for references to this state in all .sls files
    REFERENCES=$(grep -r "$SALT_REF" "$STATE_DIR" 2>/dev/null | grep -v "^Binary" || true)

    if [ -n "$REFERENCES" ]; then
      REF_COUNT=$(echo "$REFERENCES" | wc -l)
      # Exit with code 2 to block and show error
      {
        echo "BLOCK: Salt state file move would break $REF_COUNT reference(s)"
        echo ""
        echo "State: $SALT_REF"
        echo "File: $SOURCE_FILE"
        echo ""
        echo "Found references in:"
        echo "$REFERENCES" | cut -d: -f1 | sort -u | while read -r file; do
          echo "  - $file"
        done
        echo ""
        echo "You must update all references before moving this file."
      } >&2
      exit 2
    fi
  fi

  # Check for moving files from provisioning/ that are referenced in states
  if [[ "$SOURCE_FILE" =~ provisioning/(.+)$ ]]; then
    PROV_PATH="${BASH_REMATCH[1]}"
    # Look for salt:// references to this file
    SALT_REFS=$(grep -r "salt://$PROV_PATH" "$STATE_DIR" 2>/dev/null | grep -v "^Binary" || true)

    if [ -n "$SALT_REFS" ]; then
      REF_COUNT=$(echo "$SALT_REFS" | wc -l)
      {
        echo "BLOCK: Moving provisioning file would break $REF_COUNT salt:// reference(s)"
        echo ""
        echo "File: $SOURCE_FILE"
        echo "Salt path: salt://$PROV_PATH"
        echo ""
        echo "Found references in:"
        echo "$SALT_REFS" | cut -d: -f1 | sort -u | while read -r file; do
          echo "  - $file"
        done
        echo ""
        echo "You must update all salt:// references before moving this file."
      } >&2
      exit 2
    fi
  fi
fi

# Check for dangerous patterns
if [[ "$COMMAND" =~ (rm\ -rf\ /|dd\ if=/dev/zero|mkfs|fdisk) ]]; then
  echo "BLOCK: Dangerous command detected" >&2
  exit 2
fi

# Allow the operation
exit 0
