#!/bin/bash
# Route standard Claude tools to Desktop Commander MCP
# Exit 2 = block original tool (we'll handle it)
# Exit 0 = allow original tool (fallback)

# Don't use -e to avoid early exit on jq parse errors
set -uo pipefail

# Check if Desktop Commander is available
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ jq not found. falling back to standard tools" >&2
    exit 0
fi

# Parse tool input safely
TOOL_NAME="${TOOL_NAME:-}"
TOOL_INPUT="${TOOL_INPUT:-{}}"

# Exit early if no tool name
if [ -z "$TOOL_NAME" ]; then
    exit 0
fi

# Helper function to safely extract JSON field
get_json_field() {
    local field="$1"
    local default="${2:-empty}"
    printf '%s' "$TOOL_INPUT" | jq -r ".$field // $default" 2>/dev/null || echo ""
}

case "$TOOL_NAME" in
    "Edit")
        FILE_PATH=$(get_json_field "file_path")
        OLD_STRING=$(get_json_field "old_string")
        
        if [ -n "$FILE_PATH" ] && [ -n "$OLD_STRING" ]; then
            echo "🔀 routing Edit → Desktop Commander edit_block" >&2
            echo "   file: $FILE_PATH" >&2
            exit 2
        fi
        ;;
        
    "Write")
        FILE_PATH=$(get_json_field "file_path")
        
        if [ -n "$FILE_PATH" ]; then
            echo "🔀 routing Write → Desktop Commander write_file" >&2
            echo "   file: $FILE_PATH" >&2
            echo "   mode: rewrite (full file replacement)" >&2
            exit 2
        fi
        ;;
        
    "Read")
        FILE_PATH=$(get_json_field "file_path")
        
        if [ -n "$FILE_PATH" ]; then
            OFFSET=$(get_json_field "offset" "0")
            LIMIT=$(get_json_field "limit" "1000")
            echo "🔀 routing Read → Desktop Commander read_file" >&2
            echo "   file: $FILE_PATH" >&2
            echo "   offset: $OFFSET, limit: $LIMIT" >&2
            exit 2
        fi
        ;;
        
    "Grep")
        PATTERN=$(get_json_field "pattern")
        
        if [ -n "$PATTERN" ]; then
            PATH_VAL=$(get_json_field "path" '".\"')
            GLOB=$(get_json_field "glob")
            echo "🔀 routing Grep → Desktop Commander start_search" >&2
            echo "   searchType: content" >&2
            echo "   pattern: $PATTERN" >&2
            [ -n "$GLOB" ] && echo "   filePattern: $GLOB" >&2
            exit 2
        fi
        ;;
        
    "Glob")
        PATTERN=$(get_json_field "pattern")
        
        if [ -n "$PATTERN" ]; then
            echo "🔀 routing Glob → Desktop Commander start_search" >&2
            echo "   searchType: files" >&2
            echo "   pattern: $PATTERN" >&2
            exit 2
        fi
        ;;
esac

# Default: allow original tool
exit 0
