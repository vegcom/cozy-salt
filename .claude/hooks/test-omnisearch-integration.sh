#!/bin/bash
# Test suite for omnisearch-integration.sh hook

HOOK_SCRIPT="$(dirname "$0")/omnisearch-integration.sh"
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Omnisearch Integration Hook Test Suite"
echo "========================================"

# Test function
test_hook() {
    local name="$1"
    local tool="$2"
    local input="$3"
    local expect_warn="$4"

    echo -e "\n${YELLOW}Testing: $name${NC}"

    local output
    output=$(TOOL_NAME="$tool" TOOL_INPUT="$input" "$HOOK_SCRIPT" 2>&1)
    local exit_code=$?

    # All tests should exit 0 (non-blocking)
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ FAIL: Hook exited with code $exit_code${NC}"
        ((FAILED++))
        return 1
    fi

    # Check for warnings
    if [ "$expect_warn" = "yes" ]; then
        if echo "$output" | grep -q "⚠️"; then
            echo -e "${GREEN}✓ PASS: Warning displayed as expected${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ FAIL: Expected warning not found${NC}"
            ((FAILED++))
        fi
    else
        if echo "$output" | grep -q "⚠️"; then
            echo -e "${RED}✗ FAIL: Unexpected warning${NC}"
            ((FAILED++))
        else
            echo -e "${GREEN}✓ PASS: No warning (correct)${NC}"
            ((PASSED++))
        fi
    fi
}

# Run tests

# Non-destructive operations (no warnings expected)
test_hook "Read operation" "Read" '{"file_path":"/tmp/test.txt"}' "no"
test_hook "Grep operation" "Grep" '{"pattern":"TODO"}' "no"
test_hook "Small edit" "Edit" '{"file_path":"/tmp/test","old_string":"a","new_string":"b"}' "no"

# Destructive operations (warnings expected)
test_hook "Large edit" "Edit" '{"file_path":"srv/salt/test.sls","old_string":"'$(printf 'line\n%.0s' {1..15})'","new_string":"new"}' "yes"
test_hook "File move" "Bash" '{"command":"mv srv/salt/old.sls new.sls"}' "yes"
test_hook "File delete" "Bash" '{"command":"rm provisioning/config.conf"}' "yes"
test_hook "Critical file write" "Write" '{"file_path":"srv/salt/new.sls","content":"test"}' "yes"
test_hook "Refactor command" "Bash" '{"command":"refactor scripts/test.sh"}' "yes"

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "========================================"

[ $FAILED -eq 0 ] && exit 0 || exit 1
