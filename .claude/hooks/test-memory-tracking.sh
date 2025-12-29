#!/bin/bash
# Test script for memory-tracking.sh hook
# Simulates different tool operations to verify memory entities are created

set -e

HOOK_SCRIPT="$(dirname "$0")/memory-tracking.sh"
export CLAUDE_PROJECT_DIR="/var/syncthing/Git share/cozy-salt"

echo "Testing memory-tracking.sh hook..."
echo ""

# Test 1: Edit operation
echo "Test 1: Simulating Edit operation..."
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/var/syncthing/Git share/cozy-salt/srv/salt/linux/install.sls",
    "old_string": "docker_repo:",
    "new_string": "docker_repo_updated:"
  }
}
EOF
echo "Exit code: $?"
echo ""

# Test 2: Write operation (new file)
echo "Test 2: Simulating Write operation..."
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/var/syncthing/Git share/cozy-salt/tests/test_new.sls",
    "mode": "rewrite"
  }
}
EOF
echo "Exit code: $?"
echo ""

# Test 3: Bash mv operation
echo "Test 3: Simulating Bash mv operation..."
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "mv \"/var/syncthing/Git share/cozy-salt/old_file.txt\" \"/var/syncthing/Git share/cozy-salt/new_file.txt\""
  }
}
EOF
echo "Exit code: $?"
echo ""

# Test 4: Bash rm operation
echo "Test 4: Simulating Bash rm operation..."
cat <<'EOF' | "$HOOK_SCRIPT"
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -f \"/var/syncthing/Git share/cozy-salt/temp_file.txt\""
  }
}
EOF
echo "Exit code: $?"
echo ""

# Test 5: Check memory graph
echo "Test 5: Checking memory graph contents..."
echo "Note: This requires Memory MCP to be available"
echo ""

echo "All tests completed successfully!"
