#!/bin/bash
# Demo: Omnisearch integration hook in action
# Shows how the hook warns before destructive operations

set -euo pipefail

HOOK="/var/syncthing/Git share/cozy-salt/.claude/hooks/omnisearch-integration.sh"

echo "========================================"
echo "Omnisearch Integration Demo"
echo "========================================"
echo ""

# Demo 1: Safe operation (no warning)
echo "1. Safe operation: Reading a file"
echo "   Command: Read {\"file_path\": \"README.md\"}"
echo ""
TOOL_NAME="Read" TOOL_INPUT='{"file_path":"README.md"}' "$HOOK" 2>&1 | grep -q "⚠️" && echo "   ❌ Unexpected warning" || echo "   ✅ No warning (correct)"
echo ""

# Demo 2: File move (warning expected)
echo "2. Destructive operation: Moving a Salt state"
echo "   Command: mv srv/salt/old.sls srv/salt/new.sls"
echo ""
TOOL_NAME="Bash" TOOL_INPUT='{"command":"mv srv/salt/old.sls srv/salt/new.sls"}' "$HOOK" 2>&1 | head -8
echo ""

# Demo 3: Large edit (warning expected)
echo "3. Risky operation: Large edit to critical file"
echo "   Editing: srv/pillar/secrets.sls (15+ lines)"
echo ""
TOOL_NAME="Edit" TOOL_INPUT='{
  "file_path":"srv/pillar/secrets.sls",
  "old_string":"'"$(printf 'line %d\n' {1..15})"'",
  "new_string":"replaced"
}' "$HOOK" 2>&1 | head -8
echo ""

# Demo 4: New critical file (warning expected)
echo "4. New file in critical area: srv/salt/newstate.sls"
echo "   Command: Write new state file"
echo ""
TOOL_NAME="Write" TOOL_INPUT='{"file_path":"srv/salt/newstate.sls","content":"# new state"}' "$HOOK" 2>&1 | head -8
echo ""

# Demo 5: Refactor command (warning expected)
echo "5. Refactoring operation"
echo "   Command: refactor scripts/setup.sh"
echo ""
TOOL_NAME="Bash" TOOL_INPUT='{"command":"refactor scripts/setup.sh"}' "$HOOK" 2>&1 | head -8
echo ""

echo "========================================"
echo "Demo complete!"
echo ""
echo "Key takeaway: Hook warns before destructive ops,"
echo "suggests checking Omnisearch/grep first (CLAUDE.md rule #3)"
echo "========================================"
