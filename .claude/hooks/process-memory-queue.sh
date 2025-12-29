#!/bin/bash
# Process memory queue - reads .claude/memory-queue.jsonl and outputs MCP commands
# Claude can source this script to process pending memory operations

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_QUEUE="$PROJECT_DIR/.claude/memory-queue.jsonl"
MEMORY_PROCESSED="$PROJECT_DIR/.claude/memory-processed.jsonl"

if [ ! -f "$MEMORY_QUEUE" ]; then
  echo "No memory queue found at $MEMORY_QUEUE"
  exit 0
fi

# Check if queue is empty
if [ ! -s "$MEMORY_QUEUE" ]; then
  echo "Memory queue is empty"
  exit 0
fi

# Count pending operations
PENDING_COUNT=$(wc -l < "$MEMORY_QUEUE")
echo "Processing $PENDING_COUNT memory operations from queue..."
echo ""

# Group operations by type for batch processing
# SECURITY: Use template with mktemp to prevent race conditions and symlink attacks
ENTITY_OPS=$(mktemp -t entity-ops.XXXXXX)
RELATION_OPS=$(mktemp -t relation-ops.XXXXXX)
trap 'rm -f "$ENTITY_OPS" "$RELATION_OPS"' EXIT

# Parse queue and group operations
while IFS= read -r line; do
  OPERATION=$(echo "$line" | jq -r '.operation')
  # Extract data as compact JSON on one line
  DATA=$(echo "$line" | jq -c '.data')

  case "$OPERATION" in
    "create_entity")
      echo "$DATA" >> "$ENTITY_OPS"
      ;;
    "create_relation")
      echo "$DATA" >> "$RELATION_OPS"
      ;;
  esac
done < "$MEMORY_QUEUE"

# Output entity batch operations
if [ -s "$ENTITY_OPS" ]; then
  ENTITY_COUNT=$(wc -l < "$ENTITY_OPS")
  echo "Creating $ENTITY_COUNT entities:"
  echo ""
  echo "Call mcp__memory__create_entities with this entities array:"
  echo '```json'
  jq -s '.' "$ENTITY_OPS"
  echo '```'
  echo ""
fi

# Output relation batch operations
if [ -s "$RELATION_OPS" ]; then
  RELATION_COUNT=$(wc -l < "$RELATION_OPS")
  echo "Creating $RELATION_COUNT relations:"
  echo ""
  echo "Call mcp__memory__create_relations with this relations array:"
  echo '```json'
  jq -s '.' "$RELATION_OPS"
  echo '```'
  echo ""
fi

# Move processed queue to history
cat "$MEMORY_QUEUE" >> "$MEMORY_PROCESSED"
> "$MEMORY_QUEUE"

# Cleanup handled by trap on EXIT

echo "Memory queue processing complete!"
echo "Queue cleared. Processed entries saved to memory-processed.jsonl"
