# Memory Tracking Hook System

Automatically builds a knowledge graph of all file operations using Memory MCP.

## How It Works

### 1. Automatic Tracking (memory-tracking.sh)

The hook runs automatically on `PostToolUse` for these operations:
- **Edit**: Tracks what changed, why, and relationships
- **Write**: Tracks file creation/updates and dependencies
- **Bash**: Tracks file moves, renames, and deletions

All operations are queued to `.claude/memory-queue.jsonl` for batch processing.

### 2. Queue Processing (process-memory-queue.sh)

Claude periodically processes the queue to update the Memory MCP knowledge graph.

Run manually:
```bash
.claude/hooks/process-memory-queue.sh
```

This outputs the MCP commands needed to create entities and relations in batch.

### 3. Memory Graph Structure

**Entity Types:**
- `file`: Represents a file in the codebase
  - Observations: last edited, file type, status (active/moved/deleted)
- `change`: Represents a specific modification
  - Observations: type, file affected, timestamp, context

**Relation Types:**
- `modified`: Links change to file it modified
- `created`: Links change to file it created
- `updated`: Links change to file it updated
- `includes`: Salt state includes another state
- `references`: Salt state references a file (salt://)
- `moved_from` / `moved_to`: File move operations
- `replaces`: New file replaces old file after move
- `deleted`: File deletion

## What Gets Tracked

### Edit Operations
```yaml
Entity: "srv/salt/linux/install.sls"
Type: file
Observations:
  - "Last edited: 2025-12-28T10:30:00Z"
  - "Type: sls"

Entity: "srv/salt/linux/install.sls@2025-12-28T10:30:00Z"
Type: change
Observations:
  - "Type: modified"
  - "File: srv/salt/linux/install.sls"
  - "When: 2025-12-28T10:30:00Z"
  - "Context: docker_repo"

Relation: change -> file (modified)
```

### Write Operations
```yaml
Entity: "tests/test_new.sls"
Type: file
Observations:
  - "Created/Updated: 2025-12-28T10:31:00Z"
  - "Type: sls"
  - "Status: active"

Entity: "tests/test_new.sls@2025-12-28T10:31:00Z"
Type: change
Observations:
  - "Type: created"
  - "File: tests/test_new.sls"
  - "When: 2025-12-28T10:31:00Z"

Relation: change -> file (created)
```

### Bash Move Operations
```yaml
Entity: "old_file.txt"
Type: file
Observations:
  - "Status: moved to new_file.txt"
  - "Moved at: 2025-12-28T10:32:00Z"

Entity: "new_file.txt"
Type: file
Observations:
  - "Status: active"
  - "Moved from: old_file.txt"
  - "Type: txt"

Relations:
  - change -> old_file.txt (moved_from)
  - change -> new_file.txt (moved_to)
  - new_file.txt -> old_file.txt (replaces)
```

### Salt Dependencies
For .sls files, also tracks:
```yaml
# From: include statements
Relation: "srv/salt/windows/win.sls" -> "srv/salt/windows/install.sls" (includes)

# From: salt:// references
Relation: "srv/salt/linux/install.sls" -> "provisioning/packages.sls" (references)
```

## Queue File Format

`.claude/memory-queue.jsonl` (JSON Lines):
```json
{"timestamp":"2025-12-28T10:30:00Z","operation":"create_entity","data":{"name":"srv/salt/linux/install.sls","entityType":"file","observations":["Last edited: 2025-12-28T10:30:00Z","Type: sls"]}}
{"timestamp":"2025-12-28T10:30:00Z","operation":"create_relation","data":{"from":"change_id","to":"srv/salt/linux/install.sls","relationType":"modified"}}
```

## Processing the Queue

### Manual Processing
```bash
# View pending operations
cat .claude/memory-queue.jsonl | jq .

# Process queue
.claude/hooks/process-memory-queue.sh
```

### Viewing Memory Graph
```bash
# In Claude, use Memory MCP tools:
mcp__memory__read_graph           # View entire graph
mcp__memory__search_nodes "file"  # Search for files
mcp__memory__open_nodes ["srv/salt/linux/install.sls"]  # View specific file
```

## Configuration

Hook is registered in `.claude/settings.json`:
```json
{
  "matcher": "Edit|Write|Bash",
  "hooks": [{
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/memory-tracking.sh",
    "timeout": 15
  }]
}
```

## Benefits

1. **Context Persistence**: Track what you've changed across sessions
2. **Dependency Mapping**: Understand file relationships automatically
3. **Change History**: See why files were modified
4. **Safe Refactoring**: Know what depends on what before moving files
5. **Onboarding**: New sessions can query the graph to understand recent work

## Troubleshooting

**Queue not updating?**
- Check hook syntax: `bash -n .claude/hooks/memory-tracking.sh`
- Verify permissions: `chmod +x .claude/hooks/memory-tracking.sh`
- Check settings.json is valid: `jq empty .claude/settings.json`

**Memory graph empty?**
- Run processor: `.claude/hooks/process-memory-queue.sh`
- Manually create entities from queue output

**Hook timeout?**
- Queue writes are fast (< 1s)
- If timeout occurs, increase timeout in settings.json
- Check disk space and permissions

## Testing

Run the test suite:
```bash
.claude/hooks/test-memory-tracking.sh
```

This simulates Edit, Write, and Bash operations to verify queue creation.
