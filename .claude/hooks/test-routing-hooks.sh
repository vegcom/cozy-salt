#!/bin/bash
# Validate Desktop Commander routing hooks

set -euo pipefail

HOOK_SCRIPT=".claude/hooks/route-to-desktop-commander.sh"
SETTINGS_FILE=".claude/settings.json"

echo "=== Testing Desktop Commander Routing Hooks ==="
echo

# Test 1: Validate settings.json structure
echo "1. Validating settings.json structure..."
if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
    echo "❌ FAIL: Invalid JSON in settings.json"
    exit 1
fi

HOOKS_OBJECT=$(jq -e '.hooks' "$SETTINGS_FILE" 2>/dev/null || echo "null")
if [ "$HOOKS_OBJECT" = "null" ]; then
    echo "❌ FAIL: No hooks object in settings.json"
    exit 1
fi
echo "✓ Valid JSON structure"

# Test 2: Check PreToolUse hooks exist
echo
echo "2. Checking PreToolUse hooks..."
PRE_HOOKS=$(jq -e '.hooks.PreToolUse' "$SETTINGS_FILE" 2>/dev/null || echo "null")
if [ "$PRE_HOOKS" = "null" ]; then
    echo "❌ FAIL: No PreToolUse hooks found"
    exit 1
fi

# Test 3: Verify routing hook is registered
echo "✓ PreToolUse hooks found"
echo
echo "3. Verifying routing hook registration..."
ROUTING_MATCHER=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Edit|Write|Read|Grep|Glob") | .matcher' "$SETTINGS_FILE")
if [ -z "$ROUTING_MATCHER" ]; then
    echo "❌ FAIL: Routing hook not registered in PreToolUse"
    exit 1
fi
echo "✓ Routing hook registered: $ROUTING_MATCHER"

# Test 4: Check hook script exists and is executable
echo
echo "4. Checking hook script..."
if [ ! -f "$HOOK_SCRIPT" ]; then
    echo "❌ FAIL: Hook script not found: $HOOK_SCRIPT"
    exit 1
fi
if [ ! -x "$HOOK_SCRIPT" ]; then
    echo "❌ FAIL: Hook script not executable"
    exit 1
fi
echo "✓ Hook script exists and is executable"

# Test 5: Validate hook script syntax
echo
echo "5. Validating hook script syntax..."
if ! bash -n "$HOOK_SCRIPT" 2>/dev/null; then
    echo "❌ FAIL: Syntax errors in hook script"
    exit 1
fi
echo "✓ No syntax errors"

# Test 6: Test Edit tool routing
echo
echo "6. Testing Edit tool routing..."
export TOOL_NAME="Edit"
export TOOL_INPUT='{"file_path":"/tmp/test.txt","old_string":"foo","new_string":"bar"}'
export CLAUDE_PROJECT_DIR="$(pwd)"

OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "✓ Edit tool correctly blocked (exit 2)"
    echo "  Output: $OUTPUT"
else
    echo "❌ FAIL: Edit tool should exit 2, got ${EXIT_CODE:-0}"
    exit 1
fi

# Test 7: Test Write tool routing
echo
echo "7. Testing Write tool routing..."
export TOOL_NAME="Write"
export TOOL_INPUT='{"file_path":"/tmp/test.txt","content":"test content"}'

OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "✓ Write tool correctly blocked (exit 2)"
    echo "  Output: $OUTPUT"
else
    echo "❌ FAIL: Write tool should exit 2, got ${EXIT_CODE:-0}"
    exit 1
fi

# Test 8: Test Read tool routing
echo
echo "8. Testing Read tool routing..."
export TOOL_NAME="Read"
export TOOL_INPUT='{"file_path":"/tmp/test.txt","offset":0,"limit":100}'

OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "✓ Read tool correctly blocked (exit 2)"
    echo "  Output: $OUTPUT"
else
    echo "❌ FAIL: Read tool should exit 2, got ${EXIT_CODE:-0}"
    exit 1
fi

# Test 9: Test Grep tool routing
echo
echo "9. Testing Grep tool routing..."
export TOOL_NAME="Grep"
export TOOL_INPUT='{"pattern":"TODO","path":".","glob":"*.py"}'

OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "✓ Grep tool correctly blocked (exit 2)"
    echo "  Output: $OUTPUT"
else
    echo "❌ FAIL: Grep tool should exit 2, got ${EXIT_CODE:-0}"
    exit 1
fi

# Test 10: Test Glob tool routing
echo
echo "10. Testing Glob tool routing..."
export TOOL_NAME="Glob"
export TOOL_INPUT='{"pattern":"*.sls","path":"srv/salt"}'

OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 2 ]; then
    echo "✓ Glob tool correctly blocked (exit 2)"
    echo "  Output: $OUTPUT"
else
    echo "❌ FAIL: Glob tool should exit 2, got ${EXIT_CODE:-0}"
    exit 1
fi

# Test 11: Test unknown tool passthrough
echo
echo "11. Testing unknown tool passthrough..."
export TOOL_NAME="UnknownTool"
export TOOL_INPUT='{}'

EXIT_CODE=0
OUTPUT=$("$HOOK_SCRIPT" 2>&1) || EXIT_CODE=$?
if [ "${EXIT_CODE}" -eq 0 ]; then
    echo "✓ Unknown tool correctly allowed (exit 0)"
else
    echo "❌ FAIL: Unknown tool should exit 0, got ${EXIT_CODE}"
    exit 1
fi

# Test 12: Check timeout values
echo
echo "12. Checking timeout values..."
TIMEOUT=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Edit|Write|Read|Grep|Glob") | .hooks[0].timeout' "$SETTINGS_FILE")
if [ "$TIMEOUT" -lt 1 ] || [ "$TIMEOUT" -gt 30 ]; then
    echo "⚠️ WARNING: Timeout $TIMEOUT seems unusual (expected 1-30 seconds)"
else
    echo "✓ Timeout value reasonable: ${TIMEOUT}s"
fi

# Test 13: Verify jq dependency
echo
echo "13. Verifying jq dependency..."
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ WARNING: jq not installed - hooks will fall back to standard tools"
else
    echo "✓ jq is available"
fi

echo
echo "=== All Tests Passed ✓ ==="
echo
echo "Summary:"
echo "- Edit → Desktop Commander edit_block"
echo "- Write → Desktop Commander write_file (mode=rewrite)"
echo "- Read → Desktop Commander read_file"
echo "- Grep → Desktop Commander start_search (searchType=content)"
echo "- Glob → Desktop Commander start_search (searchType=files)"
echo
echo "Hooks are configured and functional!"
