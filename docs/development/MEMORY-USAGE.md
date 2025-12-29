# Using the Memory System in cozy-salt

The Memory MCP system automatically tracks all changes to the cozy-salt codebase, building a knowledge graph of your infrastructure code. This guide shows how to use it effectively.

## Quick Start

### Searching the Knowledge Graph

**Find all recent changes to Linux configs:**
```bash
# In Claude Code prompt:
Query the memory graph for entities related to "linux" and "config"
```

The memory system will return all files, changes, and relationships tagged with those terms.

**Find files that reference a specific state:**
```bash
# Search for files that include or reference another file
```

### Common Queries

#### 1. Understanding Dependencies

**"Show me what files depend on packages.sls"**
```bash
# Memory will return all relations where something "references" or "includes" packages.sls
# This is crucial before moving or renaming files
```

#### 2. Tracking Recent Changes

**"What files were changed in the last session?"**
```bash
# Memory shows all "change" entities with timestamps
# Each change is linked to the file it modified
```

#### 3. Finding Related Configurations

**"Show me all Salt states related to Docker"**
```bash
# Memory searches entity observations for "docker"
# Returns states, files, and changes tagged with Docker concepts
```

## How the Memory System Works

### Automatic Tracking

The memory system automatically tracks:

1. **File Edits** - Every Edit operation records:
   - What file was changed
   - When it was changed
   - What context (e.g., "fixed docker image")

2. **File Creation** - Every Write operation records:
   - New file path
   - File type (sls, sh, conf, etc.)
   - Creation context

3. **File Operations** - Every Bash operation records:
   - File moves/renames
   - File deletions
   - System command execution affecting files

### Salt-Specific Intelligence

For SaltStack files (.sls), the system also tracks:

**Include relationships:**
```yaml
# If you edit a file with:
include:
  - linux.docker

# Memory records: this-state -> linux.docker (includes)
```

**File references:**
```yaml
# If you reference provisioning files:
/etc/docker/daemon.json:
  file.managed:
    - source: salt://provisioning/docker-daemon.json

# Memory records: this-state -> provisioning/docker-daemon.json (references)
```

## Using Memory with Your Workflows

### Before Moving/Renaming Files

1. **Plan the change:**
   ```bash
   # Query memory for all files that reference the old path
   "Show me all Salt states that reference srv/salt/linux/install.sls"
   ```

2. **Update all references:**
   - The search results show exactly which files need updates
   - Edit each one to point to the new path

3. **Verify completeness:**
   ```bash
   # Query again to confirm no old references remain
   "Search the memory graph for references to the old path"
   ```

### Understanding State Flows

1. **Trace a state execution:**
   ```bash
   # Query for all states that include a specific state
   "Show me all states that include linux.docker"
   ```

2. **See the full chain:**
   - Memory shows the complete include tree
   - Helps you understand execution order

### Onboarding New Team Members

New team members can query the memory graph to:

1. **Understand recent work:**
   ```bash
   "What changes were made to Windows provisioning this week?"
   ```

2. **See architecture decisions:**
   ```bash
   "Show me all files related to security or encryption"
   ```

3. **Find examples:**
   ```bash
   "Find other states that configure SSH similar to how we do it"
   ```

## Memory Graph Entities and Relations

### Entity Types

- **file**: A file in the codebase (paths like `srv/salt/linux/docker.sls`)
- **change**: A specific modification (what changed, when, and why)

### Relation Types

| Type | Meaning |
|------|---------|
| `includes` | State A includes State B (via include directive) |
| `references` | State A references a file (via salt:// or source:) |
| `modified` | A change modified this file |
| `created` | A change created this file |
| `updated` | A change updated this file |
| `moved_from` / `moved_to` | File was moved in this change |
| `replaces` | New file replaces old file after move |
| `deleted` | File was deleted |

## Integration with Claude Code

### Automated Memory in Claude Sessions

When you work in Claude Code sessions:
1. Every file you edit is automatically tracked
2. Every file you create is recorded
3. Every file operation (move, delete) updates the graph
4. Dependencies are extracted from Salt include/reference statements

### Querying During Development

In any Claude Code conversation, you can:

```bash
# Search for related code
"Find all Salt states that configure package managers"

# Get context before refactoring
"Show me everything that depends on packages.sls"

# Understand architecture
"What's the dependency chain from top.sls to docker installation?"
```

## Example Workflows

### Adding a New Service

1. **Plan the implementation:**
   ```bash
   "Show me similar service installations like nginx or docker"
   # Memory returns examples you can learn from
   ```

2. **Implement the state:**
   - Edit `srv/salt/<platform>/<service>.sls`
   - Edit `srv/salt/top.sls` to include the new state
   - Memory automatically tracks both changes

3. **Verify integration:**
   ```bash
   "Show me all references to <service> and all states that include it"
   # Confirms your state is properly integrated
   ```

### Fixing a Security Issue

1. **Understand the scope:**
   ```bash
   "Show me all states and files related to [security topic]"
   # Memory shows everywhere this needs to be fixed
   ```

2. **Make corrections:**
   - Edit all affected files
   - Memory tracks each change

3. **Verify completeness:**
   ```bash
   "Are there any remaining references to the old [insecure thing]?"
   # Memory confirms all instances are fixed
   ```

## Best Practices

### 1. Be Descriptive in Claude

When working, be explicit about context:
- "Fixed hardcoded password in docker configuration" (better than just "fixed")
- "Added GPU support to RHEL minion" (better than "added line to rhel.sls")

This context is stored in memory and helps future sessions understand your work.

### 2. Keep Related Changes Together

If your change affects multiple files (e.g., updating a package and its configuration), make them in the same session. Memory will see them as related.

### 3. Review Memory Before Large Refactors

Always query what depends on what before:
- Moving files
- Renaming states
- Changing pillar structure
- Modifying package lists

### 4. Use Memory for Documentation

Instead of writing comprehensive documentation, let memory generate it:
```bash
"Generate a summary of all Linux provisioning states and their dependencies"
```

## Troubleshooting

### Memory Graph Seems Empty

1. Make sure changes were tracked:
   ```bash
   ls -la .claude/memory-queue.jsonl
   ```

2. Process the queue manually:
   ```bash
   .claude/hooks/process-memory-queue.sh
   ```

### Some Relations Missing

- Memory only tracks what it can extract from code
- Manual include statements are tracked automatically
- Complex state flows involving pillar conditionals may not be captured

To add context, edit states with comments:
```yaml
# This state is conditionally included based on grains['os']
# See linux.init for the conditional logic
```

### Old Changes Still Visible

Memory doesn't forget—it's a permanent record. This is intentional. You can filter by date when querying:
```bash
"Show me changes to docker configuration made in the last month"
```

## See Also

- `.claude/hooks/MEMORY-TRACKING.md` - Technical details for developers
- [CONTRIBUTING.md](CONTRIBUTING.md) - General contribution workflow
- [../security/SECURITY.md](../security/SECURITY.md) - Security-specific considerations
