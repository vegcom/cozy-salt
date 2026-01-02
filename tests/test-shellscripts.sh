#!/bin/bash
# Lint all shell scripts with shellcheck

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=== Shell Script Linting with shellcheck ==="

# Check if shellcheck is installed
if ! command -v shellcheck &> /dev/null; then
    echo "ERROR: shellcheck is not installed"
    echo "Install: apt install shellcheck  or  brew install shellcheck"
    exit 1
fi

# Find all .sh files
SHELL_SCRIPTS=$(find "$PROJECT_ROOT" -type f -name "*.sh" ! -path "*/\.git/*")

if [ -z "$SHELL_SCRIPTS" ]; then
    echo "No shell scripts found"
    exit 0
fi

FAILED=0

for script in $SHELL_SCRIPTS; do
    echo "Checking: $script"
    if ! shellcheck "$script"; then
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "=== FAILED: $FAILED script(s) have issues ==="
    exit 1
else
    echo ""
    echo "=== PASSED: All shell scripts are clean ==="
fi
