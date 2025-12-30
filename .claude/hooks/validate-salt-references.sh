#!/bin/bash
# Validates Salt state file references when editing .sls files
# Runs on PostToolUse for Edit/Write operations

set -e

# Load input from environment variables
TOOL_INPUT="${TOOL_INPUT:-{}}"
TOOL_NAME="${TOOL_NAME:-unknown}"
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

# Only check Salt state files
if [[ ! "$FILE_PATH" =~ \.sls$ ]]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="$PROJECT_DIR/srv/salt"
PROVISIONING_DIR="$PROJECT_DIR/provisioning"

# If this is top.sls, validate grain matching syntax
if [[ "$FILE_PATH" == */top.sls ]]; then
  if grep -q "G@os_family" "$FILE_PATH" 2>/dev/null; then
    {
      echo ""
      echo "WARNING: top.sls contains 'G@' grain syntax"
      echo ""
      echo "This is incorrect when using '- match: grain'. Use:"
      echo "  'os_family:Windows':"
      echo "    - match: grain"
      echo "    - windows"
      echo ""
      echo "NOT: 'G@os_family:Windows' (G@ is for compound matchers only)"
      echo ""
    } >&2
    # Don't block, just warn (exit 1 = non-blocking warning)
    exit 1
  fi
fi

# Validate salt:// references in state files
BROKEN_REFS=$(grep -o "salt://[a-zA-Z0-9/_.-]*" "$FILE_PATH" 2>/dev/null || true)

if [ -n "$BROKEN_REFS" ]; then
  WARNINGS=""
  while IFS= read -r REF; do
    # Check if the referenced file exists
    # salt://packages.sls -> provisioning/packages.sls or srv/salt/packages.sls
    REF_PATH="${REF#salt://}"
    REF_FILE="$STATE_DIR/$REF_PATH"
    REF_PROV="$PROVISIONING_DIR/$REF_PATH"

    # Check for file or directory
    if [ ! -f "$REF_FILE" ] && [ ! -d "$REF_FILE" ] && [ ! -f "$REF_PROV" ] && [ ! -d "$REF_PROV" ]; then
      WARNINGS="${WARNINGS}WARNING: Reference not found: $REF\n"
      WARNINGS="${WARNINGS}  Expected at: srv/salt/$REF_PATH OR provisioning/$REF_PATH\n"
    fi
  done <<< "$BROKEN_REFS"

  if [ -n "$WARNINGS" ]; then
    echo -e "$WARNINGS" >&2
    exit 1
  fi
fi

exit 0
