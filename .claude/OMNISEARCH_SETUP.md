# Omnisearch Integration - Implementation Summary

Automatic knowledge graph checking before destructive codebase operations.

## What Was Built

### 1. Core Hook: `omnisearch-integration.sh`
**Location:** `.claude/hooks/omnisearch-integration.sh`
**Purpose:** Enforces CLAUDE.md rule "check DeepWiki + Omnisearch FIRST"

**Features:**
- Detects destructive operations (mv, rm, cp, refactor, delete)
- Extracts search terms from file paths, SaltStack states, includes
- Warns before large edits (>10 lines)
- Suggests Omnisearch queries via `mcp__memory__search_nodes`
- Provides grep fallback commands
- Non-blocking (exit 0) - warns but allows operation

### 2. Test Suite: `test-omnisearch-integration.sh`
**Status:** All 8 tests passing

**Test coverage:**
- Read operations (no warning)
- Grep operations (no warning)
- Small edits (no warning)
- Large edits (warns)
- File moves (warns)
- File deletes (warns)
- New critical files (warns)
- Refactor commands (warns)

### 3. Documentation
- **OMNISEARCH_INTEGRATION.md:** Detailed hook documentation
- **README.md:** Updated with Omnisearch hook info
- **demo-omnisearch.sh:** Interactive demo showing hook behavior

## Hook Configuration

Registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/omnisearch-integration.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

**Execution order:**
1. omnisearch-integration.sh (warns)
2. route-to-desktop-commander.sh (routes)
3. validate-salt-moves.sh (validates)

## How It Works

### Detection Logic

**Bash commands:**
```bash
# Detects: mv, rm, cp, rename, delete, refactor
mv srv/salt/old.sls new.sls  → ⚠️ Warning
rm provisioning/config.conf  → ⚠️ Warning
```

**Edit operations:**
```bash
# Large edits (>10 lines) in any file
Edit: 15 lines changed  → ⚠️ Warning
Edit: 5 lines changed   → ✅ No warning
```

**Write operations:**
```bash
# New files in critical directories
Write: srv/salt/new.sls       → ⚠️ Warning
Write: srv/pillar/data.sls    → ⚠️ Warning
Write: provisioning/pkg.sls   → ⚠️ Warning
Write: scripts/setup.sh       → ⚠️ Warning
Write: /tmp/notes.txt         → ✅ No warning
```

### Search Term Extraction

Automatically extracts:
- File basenames: `old.sls` → `old.sls`
- Directory names: `srv/salt/core/init.sls` → `init.sls core`
- SaltStack state IDs: `my_state:` → `my_state`
- salt:// references: `salt://provisioning/file.conf`
- include statements: `include: - core.base`
- Command paths: extracted from destructive commands

## Example Output

```
⚠️  Major change detected. Recommended Omnisearch queries:
🔍 Omnisearch query needed: 'init.sls'
{
  "suggestion": "Before proceeding, check Omnisearch for: init.sls",
  "reason": "CLAUDE.md requires checking existing patterns first",
  "action": "Query knowledge graph for context"
}

💡 Use: mcp__memory__search_nodes to query knowledge graph
📋 Or grep: grep -Hnr 'init.sls' srv/salt/ srv/pillar/ provisioning/
```

## Usage in Practice

### Scenario 1: Moving a State File
```bash
# Claude attempts: mv srv/salt/old.sls srv/salt/new.sls
# Hook warns: Check Omnisearch for 'old.sls' and 'new.sls'
# Claude can then: Use mcp__memory__search_nodes before proceeding
```

### Scenario 2: Large Refactor
```bash
# Claude attempts: Large edit to srv/salt/core/init.sls
# Hook warns: Check existing patterns for 'init.sls core'
# Claude can then: Query knowledge graph, run grep, verify safe
```

### Scenario 3: New State Creation
```bash
# Claude attempts: Write srv/salt/newfeature.sls
# Hook warns: Check for similar patterns first
# Claude can then: Search for existing feature implementations
```

## Testing

### Run full test suite:
```bash
.claude/hooks/test-omnisearch-integration.sh
```

### Run interactive demo:
```bash
.claude/hooks/demo-omnisearch.sh
```

### Manual test:
```bash
TOOL_NAME="Bash" \
TOOL_INPUT='{"command":"mv srv/salt/test.sls srv/salt/new.sls"}' \
.claude/hooks/omnisearch-integration.sh
```

## Integration with Omnisearch

The hook suggests using `mcp__memory__search_nodes` to query the knowledge graph:

```javascript
// Claude can invoke:
mcp__memory__search_nodes({
  query: "init.sls"
})

// Returns: Entities, observations, relations related to init.sls
```

This allows Claude to:
1. Find existing implementations
2. Discover dependencies
3. Check for similar patterns
4. Verify safe to proceed

## Design Decisions

### Why Non-Blocking?
- Warnings provide guidance without preventing legitimate operations
- Claude can evaluate context and decide whether to check Omnisearch
- Avoids false positives blocking valid work

### Why Search Term Extraction?
- Automates the tedious part (finding what to search for)
- Extracts multiple relevant terms from single operation
- Handles SaltStack-specific patterns (salt://, includes)

### Why Both Omnisearch AND grep?
- Omnisearch: Knowledge graph with relationships
- grep: Fallback for literal string searches
- Covers both semantic and literal reference checking

## Maintenance

### Adding New Patterns
Edit `extract_search_terms()` function in `omnisearch-integration.sh`

### Adding New Destructive Commands
Update regex in Bash command detection:
```bash
if echo "$cmd" | grep -qE '\b(mv|rm|cp|YOUR_NEW_COMMAND)\b'; then
```

### Adjusting Sensitivity
Modify thresholds:
- Large edit threshold: Currently 10 lines
- Critical directories: srv/salt, srv/pillar, provisioning, scripts

## Files Created

```
.claude/hooks/
├── omnisearch-integration.sh          (Hook implementation)
├── test-omnisearch-integration.sh     (Test suite - 8 tests)
├── demo-omnisearch.sh                 (Interactive demo)
├── OMNISEARCH_INTEGRATION.md          (Detailed docs)
└── README.md                          (Updated with Omnisearch info)

.claude/
└── settings.json                      (Updated with hook registration)
```

## Verification

```bash
# Check hook is registered
jq '.hooks.PreToolUse[] | select(.matcher | test("Edit|Write|Bash"))' \
  .claude/settings.json

# Check hook is executable
ls -l .claude/hooks/omnisearch-integration.sh

# Run tests
.claude/hooks/test-omnisearch-integration.sh
# Expected: 8 passed, 0 failed
```

## Next Steps

1. Use the hook in real workflows
2. Adjust sensitivity based on false positive rate
3. Add more SaltStack-specific patterns as discovered
4. Integrate with DeepWiki for documentation checks

---

Implementation complete: 2025-12-28
Separate from Desktop Commander hooks (different file, different purpose)
Enforces CLAUDE.md rule #3: "grep before u ship"
