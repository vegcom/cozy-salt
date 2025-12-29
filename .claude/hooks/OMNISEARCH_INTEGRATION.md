# Omnisearch Integration Hook

Automatically queries the knowledge graph before major codebase changes to enforce CLAUDE.md's "check DeepWiki + Omnisearch FIRST" rule.

## Purpose

Prevents breaking changes by:
- Detecting destructive operations (moves, deletes, refactors)
- Extracting relevant search terms from tool inputs
- Suggesting Omnisearch queries before proceeding
- Providing grep commands as fallback

## Hook Triggers

### Edit Tool
- Large edits (>10 lines)
- Changes to SaltStack states
- Files in critical directories

### Write Tool
- New files in: srv/salt, srv/pillar, provisioning, scripts

### Bash Tool
- Commands containing: mv, rm, cp, rename, delete, refactor
- Operations on .sls, .yaml, .conf files

## Behavior

**Non-blocking**: Always exits 0 (allows operation to continue)

**Warning format**:
```
⚠️  Major change detected. Recommended Omnisearch queries:
🔍 Omnisearch query needed: 'search_term'
💡 Use: mcp__memory__search_nodes to query knowledge graph
📋 Or grep: grep -Hnr 'terms' srv/salt/ srv/pillar/ provisioning/
```

## Search Term Extraction

Automatically extracts:
- File paths and basenames
- SaltStack state IDs (declarations ending with :)
- salt:// references
- include: statements
- Command-line paths from destructive operations

## Example Scenarios

### File Move
```bash
# Tool: Bash
# Input: {"command": "mv srv/salt/old.sls srv/salt/new.sls"}
# Result: Warns with search terms: "old.sls new.sls"
```

### State Refactor
```bash
# Tool: Edit
# Input: Large edit to srv/salt/core/init.sls
# Result: Warns with search terms: "init.sls core"
```

### New State File
```bash
# Tool: Write
# Input: {"file_path": "srv/salt/newstate.sls", ...}
# Result: Warns with search terms: "newstate.sls salt"
```

## Configuration

Hook is registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/omnisearch-integration.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## Testing

Run test suite:
```bash
.claude/hooks/test-omnisearch-integration.sh
```

Expected: 8 tests pass, 0 fail

## Integration with Other Hooks

**Execution order**:
1. omnisearch-integration.sh (warns about changes)
2. route-to-desktop-commander.sh (routes file operations)
3. validate-salt-moves.sh (validates Salt-specific operations)

**Non-interference**: All hooks exit 0, so they stack without blocking

## Maintenance

Update search term patterns in `extract_search_terms()` function when:
- Adding new file types
- Supporting new SaltStack patterns
- Detecting new destructive operations

## See Also

- CLAUDE.md: Project guidelines
- validate-salt-moves.sh: Salt-specific validation
- Desktop Commander hooks: File operation routing
