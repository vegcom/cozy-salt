# Hook Configuration Documentation

validation passed. all hooks are registered and functional~

## Overview

hooks run **outside** Claude's context as shell scripts. they CANNOT directly invoke MCP tools (Memory, Sequential Thinking, etc). they CAN validate input, suggest actions, and block execution via exit codes.

## Hook Files

### `/var/syncthing/Git share/cozy-salt/.claude/hooks/todo-integration.sh`
**Status:** ✅ registered and functional
**Events:** PreToolUse, PostToolUse
**Matcher:** `TodoWrite`
**Timeout:** 5s

**PreToolUse behavior:**
- validates todo structure (content, activeForm, status required)
- checks status values (must be: pending, in_progress, completed)
- warns if multiple tasks are in_progress (best practice: only ONE)
- suggests Sequential Thinking for complex breakdowns (>3 tasks)
- exit 0: allow TodoWrite to proceed
- exit 2: block TodoWrite (validation failed)

**PostToolUse behavior:**
- extracts task graph from todos
- outputs Memory integration suggestions
- shows current/pending/completed task summary
- exit 0 always (advisory only, doesn't block)

**Validation tests:**
```bash
# test valid todo
export TOOL_NAME="TodoWrite" TOOL_EVENT="PreToolUse" \
  TOOL_INPUT='{"todos":[{"content":"Test","activeForm":"Testing","status":"in_progress"}]}'
.claude/hooks/todo-integration.sh
# expected: exit 0, validation passed

# test invalid status
export TOOL_NAME="TodoWrite" TOOL_EVENT="PreToolUse" \
  TOOL_INPUT='{"todos":[{"content":"Test","activeForm":"Testing","status":"invalid"}]}'
.claude/hooks/todo-integration.sh
# expected: exit 2, validation failed

# test memory integration
export TOOL_NAME="TodoWrite" TOOL_EVENT="PostToolUse" \
  TOOL_INPUT='{"todos":[{"content":"Fix auth","activeForm":"Fixing auth","status":"in_progress"}]}'
.claude/hooks/todo-integration.sh
# expected: exit 0, memory graph summary shown
```

### `/var/syncthing/Git share/cozy-salt/.claude/hooks/memory-tracking.sh`
**Status:** ⚠️ registered but broken
**Issue:** attempts to call `mcp memory create_entities` which doesn't exist in shell context
**Fix needed:** remove MCP invocations, output structured data for manual processing

### `/var/syncthing/Git share/cozy-salt/.claude/hooks/omnisearch-integration.sh`
**Status:** ✅ registered and functional
**Events:** PreToolUse
**Matcher:** `Edit|Write|Bash`
**Timeout:** 5s
**Documentation:** OMNISEARCH_INTEGRATION.md

**PreToolUse behavior:**
- detects destructive operations (mv, rm, cp, refactor)
- extracts search terms from file paths, SaltStack states, includes
- warns before large edits (>10 lines)
- suggests Omnisearch queries: mcp__memory__search_nodes
- provides grep fallback commands
- exit 0 always (advisory, non-blocking)

**Search term extraction:**
- file basenames and directory names
- SaltStack state IDs (declarations ending with :)
- salt:// references
- include: statements
- paths from destructive commands

**Example warning:**
```
⚠️  Major change detected. Recommended Omnisearch queries:
🔍 Omnisearch query needed: 'init.sls'
💡 Use: mcp__memory__search_nodes to query knowledge graph
📋 Or grep: grep -Hnr 'init.sls' srv/salt/ srv/pillar/ provisioning/
```

**Tests:** `.claude/hooks/test-omnisearch-integration.sh` (8 tests, all passing)

### Other hooks
see individual files for documentation

## Hook Limitations

**what hooks CAN do:**
- validate tool input (PreToolUse)
- inspect tool output (PostToolUse)
- block execution (exit 2)
- suggest actions via stderr
- run shell commands safely

**what hooks CANNOT do:**
- invoke MCP tools directly (Memory, Sequential Thinking, etc)
- modify tool input/output
- access Claude's conversation context
- make API calls to Claude

## Integration Pattern

for tools like TodoWrite that need MCP integration:

1. **PreToolUse hook** validates input and suggests MCP tools to use
2. **Claude sees suggestion** and decides whether to invoke MCP tools
3. **TodoWrite executes** if validation passed
4. **PostToolUse hook** outputs structured data for Memory integration
5. **Claude manually invokes** Memory tools based on hook suggestions

this is advisory, not automatic. hooks guide Claude's behavior but don't control it.

## Exit Codes

- **0:** allow operation to proceed (validation passed or PostToolUse completed)
- **2:** block operation (validation failed, safety issue detected)
- **other:** warning logged but operation proceeds

## Security Notes

- hooks run with user's shell permissions
- all user input must be sanitized before use in commands
- no secrets in hook files (use env vars)
- timeout prevents infinite loops (5-15s depending on complexity)
- jq required for JSON parsing (graceful fallback if missing)

---

hooks validated: 2025-12-28
next review: when adding new MCP integrations~
