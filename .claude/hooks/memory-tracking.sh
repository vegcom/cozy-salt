#!/bin/bash
# Memory tracking hook - builds knowledge graph of file operations
# Runs on PostToolUse for Edit, Write, and Bash (file moves) operations
# Logs operations to .claude/memory-queue.jsonl for processing by Claude

set -eo pipefail

# Hooks receive data via environment variables, not stdin
TOOL_NAME="${TOOL_NAME:-unknown}"
TOOL_INPUT="${TOOL_INPUT:-{}}"
TOOL_EVENT="${TOOL_EVENT:-PostToolUse}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_QUEUE="$PROJECT_DIR/.claude/memory-queue.jsonl"

# Ensure queue file exists
mkdir -p "$(dirname "$MEMORY_QUEUE")"
touch "$MEMORY_QUEUE"

# Helper: Queue a memory operation
queue_memory() {
  local operation="$1"
  local data="$2"

  # Append to JSONL queue
  echo "{\"timestamp\":\"$TIMESTAMP\",\"operation\":\"$operation\",\"data\":$data}" >> "$MEMORY_QUEUE"
}

# Helper: Create entity queue entry
queue_entity() {
  local name="$1"
  local type="$2"
  shift 2
  local observations=("$@")

  # Build observations array using jq for proper escaping
  local obs_json="[]"
  for obs in "${observations[@]}"; do
    obs_json=$(jq -nc --arg obs "$obs" --argjson arr "$obs_json" '$arr + [$obs]')
  done

  # Build entity JSON using jq for safe escaping
  local entity_json=$(jq -nc \
    --arg name "$name" \
    --arg type "$type" \
    --argjson observations "$obs_json" \
    '{name: $name, entityType: $type, observations: $observations}')

  queue_memory "create_entity" "$entity_json"
}

# Helper: Create relation queue entry
queue_relation() {
  local from="$1"
  local to="$2"
  local relation_type="$3"

  # Use jq for safe JSON construction
  local relation_json=$(jq -nc \
    --arg from "$from" \
    --arg to "$to" \
    --arg relationType "$relation_type" \
    '{from: $from, to: $to, relationType: $relationType}')

  queue_memory "create_relation" "$relation_json"
}

# Helper: Extract what changed in an Edit operation
analyze_edit() {
  local file_path="$1"
  local old_string=$(echo "$TOOL_INPUT" | jq -r '.old_string // ""')
  local new_string=$(echo "$TOOL_INPUT" | jq -r '.new_string // ""')

  # Determine type of change
  local change_type="modified"
  if [ -z "$old_string" ]; then
    change_type="added_content"
  elif [ -z "$new_string" ]; then
    change_type="removed_content"
  fi

  # Try to infer what was changed (function name, config, etc)
  local context=""
  if [[ "$old_string" =~ ^[[:space:]]*([a-zA-Z0-9_-]+): ]] || [[ "$new_string" =~ ^[[:space:]]*([a-zA-Z0-9_-]+): ]]; then
    context="${BASH_REMATCH[1]}"
  fi

  echo "$change_type:$context"
}

# Helper: Track Salt state dependencies
track_salt_dependencies() {
  local file_path="$1"

  # Only for Salt state files
  if [[ ! "$file_path" =~ \.sls$ ]]; then
    return
  fi

  # Normalize to relative path
  local rel_path="${file_path#$PROJECT_DIR/}"

  # Find include/import references
  if [ -f "$file_path" ]; then
    grep -E '^\s*(include|import):\s*$' -A 20 "$file_path" 2>/dev/null | \
      grep -oP '(?<=- )[a-zA-Z0-9._-]+' | \
      while read -r dep; do
        queue_relation "$rel_path" "srv/salt/${dep//./\/}.sls" "includes"
      done || true

    # Find salt:// file references
    grep -oP 'salt://[a-zA-Z0-9/_.-]+' "$file_path" 2>/dev/null | \
      while read -r ref; do
        local ref_file="${ref#salt://}"
        queue_relation "$rel_path" "provisioning/$ref_file" "references"
      done || true
  fi
}

# Main logic based on tool type
case "$TOOL_NAME" in
  "Edit")
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')

    if [ -n "$FILE_PATH" ]; then
      # Normalize to relative path from project root
      REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

      # Analyze what changed
      CHANGE_INFO=$(analyze_edit "$FILE_PATH")
      CHANGE_TYPE="${CHANGE_INFO%%:*}"
      CONTEXT="${CHANGE_INFO##*:}"

      # Queue change entity
      CHANGE_NAME="$REL_PATH@$TIMESTAMP"
      queue_entity "$CHANGE_NAME" "change" \
        "Type: $CHANGE_TYPE" \
        "File: $REL_PATH" \
        "When: $TIMESTAMP" \
        "Context: $CONTEXT"

      # Queue file entity update
      queue_entity "$REL_PATH" "file" \
        "Last edited: $TIMESTAMP" \
        "Type: ${FILE_PATH##*.}"

      # Queue relationship
      queue_relation "$CHANGE_NAME" "$REL_PATH" "modified"

      # Track Salt dependencies
      track_salt_dependencies "$FILE_PATH"
    fi
    ;;

  "Write")
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // ""')
    MODE=$(echo "$TOOL_INPUT" | jq -r '.mode // "rewrite"')

    if [ -n "$FILE_PATH" ]; then
      REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

      # Determine if new file or update
      if [ "$MODE" = "rewrite" ] && [ ! -f "$FILE_PATH.bak" ]; then
        ACTION="created"
      else
        ACTION="updated"
      fi

      # Queue change entity
      CHANGE_NAME="$REL_PATH@$TIMESTAMP"
      queue_entity "$CHANGE_NAME" "change" \
        "Type: $ACTION" \
        "File: $REL_PATH" \
        "When: $TIMESTAMP" \
        "Mode: $MODE"

      # Queue file entity creation/update
      queue_entity "$REL_PATH" "file" \
        "Created/Updated: $TIMESTAMP" \
        "Type: ${FILE_PATH##*.}" \
        "Status: active"

      # Queue relationship
      queue_relation "$CHANGE_NAME" "$REL_PATH" "${ACTION}"

      # Track Salt dependencies
      track_salt_dependencies "$FILE_PATH"
    fi
    ;;

  "Bash")
    COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // ""')

    # Track file moves/renames
    if [[ "$COMMAND" =~ ^mv[[:space:]]+(.+)[[:space:]]+(.+)$ ]]; then
      # Extract source and dest, removing quotes
      SRC=$(echo "${BASH_REMATCH[1]}" | sed 's/^["\x27]//;s/["\x27]$//')
      DST=$(echo "${BASH_REMATCH[2]}" | sed 's/^["\x27]//;s/["\x27]$//')

      SRC_REL="${SRC#$PROJECT_DIR/}"
      DST_REL="${DST#$PROJECT_DIR/}"

      # Queue move change entity
      CHANGE_NAME="move:$SRC_REL->$DST_REL@$TIMESTAMP"
      queue_entity "$CHANGE_NAME" "change" \
        "Type: moved" \
        "From: $SRC_REL" \
        "To: $DST_REL" \
        "When: $TIMESTAMP"

      # Queue source file entity update (mark as moved)
      queue_entity "$SRC_REL" "file" \
        "Status: moved to $DST_REL" \
        "Moved at: $TIMESTAMP"

      # Queue destination file entity
      queue_entity "$DST_REL" "file" \
        "Status: active" \
        "Moved from: $SRC_REL" \
        "Created: $TIMESTAMP" \
        "Type: ${DST##*.}"

      # Queue relationships
      queue_relation "$CHANGE_NAME" "$SRC_REL" "moved_from"
      queue_relation "$CHANGE_NAME" "$DST_REL" "moved_to"
      queue_relation "$DST_REL" "$SRC_REL" "replaces"
    fi

    # Track file deletions
    if [[ "$COMMAND" =~ ^rm[[:space:]]+-?[rf]*[[:space:]]+(.+)$ ]]; then
      # Extract file path, removing quotes
      FILE=$(echo "${BASH_REMATCH[1]}" | sed 's/^["\x27]//;s/["\x27]$//')
      FILE_REL="${FILE#$PROJECT_DIR/}"

      # Queue deletion change entity
      CHANGE_NAME="delete:$FILE_REL@$TIMESTAMP"
      queue_entity "$CHANGE_NAME" "change" \
        "Type: deleted" \
        "File: $FILE_REL" \
        "When: $TIMESTAMP"

      # Queue file entity update (mark as deleted)
      queue_entity "$FILE_REL" "file" \
        "Status: deleted" \
        "Deleted at: $TIMESTAMP"

      # Queue relationship
      queue_relation "$CHANGE_NAME" "$FILE_REL" "deleted"
    fi
    ;;
esac

# Always exit 0 - we don't want to block operations if memory fails
exit 0
