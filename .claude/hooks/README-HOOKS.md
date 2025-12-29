# Claude Hooks - cozy-salt Project

Automated validation and tracking hooks for safe Salt state management.

## Active Hooks

### 1. Memory Tracking (`memory-tracking.sh`)
**When**: PostToolUse - Edit, Write, Bash
**Purpose**: Builds knowledge graph of file operations over time
**Exit**: Always 0 (non-blocking)

Automatically queues memory operations to `.claude/memory-queue.jsonl` for:
- File edits with context about what changed
- File creation/updates
- File moves and renames
- File deletions
- Salt state dependencies (includes/references)

**See**: [MEMORY-TRACKING.md](./MEMORY-TRACKING.md) for details

### 2. Salt Move Validation (`validate-salt-moves.sh`)
**When**: PreToolUse - Bash (mv, rm commands)
**Purpose**: Prevents breaking Salt references when moving files
**Exit**: 2 (blocks), 0 (allows)

Checks before file moves:
- Salt state references (srv/salt/*.sls → state.name)
- Provisioning file references (salt://path/to/file)
- Dangerous commands (rm -rf /, etc.)

**Exit 2 blocks the operation** and shows which files reference the target.

### 3. Salt Reference Validation (`validate-salt-references.sh`)
**When**: PostToolUse - Edit, Write (.sls files)
**Purpose**: Validates Salt state references after editing
**Exit**: 1 (warns), 0 (passes)

Checks after edits:
- `top.sls` grain matcher syntax (warns about G@ usage)
- `salt://` references point to existing files
- Referenced files exist in srv/salt/ or provisioning/

**Exit 1 warns** but doesn't block (you can proceed).

### 4. YAML Linting (inline)
**When**: PostToolUse - Edit, Write (.sls files)
**Purpose**: Runs yamllint on Salt states
**Exit**: Always 0 (non-blocking)

Validates YAML syntax if yamllint is installed.

### 5. Desktop Commander Routing (`route-to-desktop-commander.sh`)
**When**: PreToolUse - Edit, Write, Read, Grep, Glob
**Purpose**: Routes file operations to Desktop Commander MCP
**Exit**: Always 0 (non-blocking)

Suggests using Desktop Commander for enhanced file operations.

### 6. OmniSearch Integration (`omnisearch-integration.sh`)
**When**: PreToolUse - Edit, Write, Bash
**Purpose**: Indexes operations for OmniSearch
**Exit**: Always 0 (non-blocking)

Tracks operations for enhanced search capabilities.

## Hook Exit Codes

```
0 = Allow (operation proceeds normally)
1 = Warn (shows message but allows operation)
2 = Block (stops operation, shows error)
```

## Configuration

Hooks are defined in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [{"command": "script.sh", "timeout": 5}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{"command": "script.sh", "timeout": 10}]
      }
    ]
  }
}
```

## Hook Input Format

All hooks receive JSON via stdin:

```json
{
  "tool_name": "Edit|Write|Bash|...",
  "tool_input": {
    "file_path": "/absolute/path/to/file",
    "command": "bash command string",
    ...
  }
}
```

Access with jq:
```bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
```

## Environment Variables

- `$CLAUDE_PROJECT_DIR`: Project root directory
- `$TOOL_INPUT`: JSON string of tool input (deprecated, use stdin)
- `$TOOL_NAME`: Name of the tool being used (deprecated, use stdin)

## Testing Hooks

Each hook has a test script:
```bash
.claude/hooks/test-memory-tracking.sh
.claude/hooks/test-routing-hooks.sh
.claude/hooks/test-salt-validation.sh
```

Validate syntax:
```bash
bash -n .claude/hooks/memory-tracking.sh
```

Validate settings.json:
```bash
jq empty .claude/settings.json
```

## Debugging

**Hook not running?**
- Check timeout setting (increase if needed)
- Verify script is executable: `chmod +x script.sh`
- Check syntax: `bash -n script.sh`

**Hook blocking when it shouldn't?**
- Check exit code logic
- Test with sample input
- Review matcher pattern

**Performance issues?**
- Reduce timeout values
- Minimize external command calls
- Use `set -e` for fast failure

## Best Practices

1. **Always exit explicitly** - Don't rely on implicit exit codes
2. **Use jq for JSON parsing** - Robust and standard
3. **Set timeouts appropriately** - 5-10s for PreToolUse, 10-15s for PostToolUse
4. **Test with real input** - Simulate actual tool calls
5. **Document exit codes** - Make behavior clear
6. **Handle errors gracefully** - Use `|| true` for non-critical commands
7. **Log to stderr** - stdout should be for user-facing messages

## File Locations

```
.claude/
├── settings.json           # Hook configuration
├── hooks/
│   ├── memory-tracking.sh           # Memory graph builder
│   ├── validate-salt-moves.sh       # Pre-move validation
│   ├── validate-salt-references.sh  # Post-edit validation
│   ├── route-to-desktop-commander.sh
│   ├── omnisearch-integration.sh
│   ├── process-memory-queue.sh      # Queue processor
│   ├── test-*.sh                    # Test scripts
│   ├── README-HOOKS.md             # This file
│   └── MEMORY-TRACKING.md          # Memory system docs
└── memory-queue.jsonl      # Pending memory operations
```

## Security Notes

Hooks run with your permissions and can execute arbitrary commands. Always:
- Validate hook sources before using
- Review hook code for security issues
- Avoid hardcoded secrets
- Sanitize file paths and inputs
- Use `set -e` to fail fast on errors
