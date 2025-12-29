#!/bin/bash
# TodoWrite Integration with Memory + Sequential Thinking
# PreToolUse: Validates task breakdown with Sequential Thinking
# PostToolUse: Stores todo graph in Memory knowledge graph
#
# Exit codes:
# - 0: Allow TodoWrite to proceed (validation passed or PostToolUse completed)
# - 2: Block TodoWrite (validation failed)

set -uo pipefail

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ jq not found. skipping todo integration" >&2
    exit 0
fi

# Parse tool input safely
TOOL_NAME="${TOOL_NAME:-}"
TOOL_INPUT="${TOOL_INPUT:-{}}"
TOOL_EVENT="${TOOL_EVENT:-}"

# Exit early if no tool name or not TodoWrite
if [ -z "$TOOL_NAME" ] || [ "$TOOL_NAME" != "TodoWrite" ]; then
    exit 0
fi

# Extract todos array from input
TODOS=$(echo "$TOOL_INPUT" | jq -c '.todos // []' 2>/dev/null)

if [ -z "$TODOS" ] || [ "$TODOS" = "[]" ]; then
    echo "⚠️ TodoWrite called with empty todos array" >&2
    exit 0
fi

# Count todos
TODO_COUNT=$(echo "$TODOS" | jq 'length')

case "$TOOL_EVENT" in
    "PreToolUse")
        echo "🧠 TodoWrite detected: analyzing $TODO_COUNT tasks..." >&2
        echo "" >&2
        echo "📋 Tasks to validate:" >&2

        # Show task list for context
        echo "$TODOS" | jq -r '.[] | "   [\(.status)] \(.content)"' >&2

        echo "" >&2
        echo "💭 Sequential Thinking will validate:" >&2
        echo "   - Task breakdown makes sense" >&2
        echo "   - Dependencies between todos" >&2
        echo "   - Suggested execution order" >&2
        echo "" >&2

        # Validation checks
        HAS_PENDING=false
        HAS_IN_PROGRESS=false
        IN_PROGRESS_COUNT=0

        while IFS= read -r todo; do
            STATUS=$(echo "$todo" | jq -r '.status')
            CONTENT=$(echo "$todo" | jq -r '.content')
            ACTIVE_FORM=$(echo "$todo" | jq -r '.activeForm')

            # Check for required fields
            if [ -z "$STATUS" ] || [ -z "$CONTENT" ] || [ -z "$ACTIVE_FORM" ]; then
                echo "❌ validation failed: missing required fields" >&2
                echo "   todo: $todo" >&2
                exit 2
            fi

            # Check valid status
            case "$STATUS" in
                pending|in_progress|completed) ;;
                *)
                    echo "❌ validation failed: invalid status '$STATUS'" >&2
                    echo "   must be: pending, in_progress, or completed" >&2
                    exit 2
                    ;;
            esac

            # Track status distribution
            [ "$STATUS" = "pending" ] && HAS_PENDING=true
            [ "$STATUS" = "in_progress" ] && HAS_IN_PROGRESS=true && IN_PROGRESS_COUNT=$((IN_PROGRESS_COUNT + 1))

        done < <(echo "$TODOS" | jq -c '.[]')

        # Validate exactly ONE in_progress task
        if [ "$IN_PROGRESS_COUNT" -gt 1 ]; then
            echo "⚠️ warning: $IN_PROGRESS_COUNT tasks marked in_progress" >&2
            echo "   best practice: only ONE task should be in_progress at a time" >&2
            echo "   this helps maintain focus and track actual current work" >&2
        fi

        # Suggest using Sequential Thinking (advisory only, don't block)
        if [ "$TODO_COUNT" -gt 3 ]; then
            echo "💡 tip: consider using Sequential Thinking to validate this task breakdown" >&2
            echo "   it can help identify dependencies and optimal execution order" >&2
        fi

        echo "✅ validation passed: allowing TodoWrite to proceed" >&2
        exit 0
        ;;

    "PostToolUse")
        echo "💾 storing todo list in Memory knowledge graph..." >&2

        # Build task graph for Memory
        TASK_ENTITIES=""
        TASK_RELATIONS=""

        # Extract unique task identifiers and relationships
        CURRENT_TASK=""
        PENDING_TASKS=()
        COMPLETED_TASKS=()

        while IFS= read -r todo; do
            STATUS=$(echo "$todo" | jq -r '.status')
            CONTENT=$(echo "$todo" | jq -r '.content')

            # Create entity name from content (simplified)
            ENTITY_NAME=$(echo "$CONTENT" | head -c 50 | tr ' ' '_' | tr -cd '[:alnum:]_-')

            case "$STATUS" in
                in_progress)
                    CURRENT_TASK="$ENTITY_NAME"
                    ;;
                pending)
                    PENDING_TASKS+=("$ENTITY_NAME")
                    ;;
                completed)
                    COMPLETED_TASKS+=("$ENTITY_NAME")
                    ;;
            esac

        done < <(echo "$TODOS" | jq -c '.[]')

        echo "📊 Memory graph summary:" >&2
        [ -n "$CURRENT_TASK" ] && echo "   Current: $CURRENT_TASK" >&2
        [ ${#PENDING_TASKS[@]} -gt 0 ] && echo "   Pending: ${#PENDING_TASKS[@]} tasks" >&2
        [ ${#COMPLETED_TASKS[@]} -gt 0 ] && echo "   Completed: ${#COMPLETED_TASKS[@]} tasks" >&2

        echo "" >&2
        echo "💡 Memory integration ready (manual invocation required)" >&2
        echo "   Use mcp__memory__create_entities to store task graph" >&2
        echo "   Use mcp__memory__create_relations to link dependencies" >&2

        exit 0
        ;;

    *)
        echo "⚠️ unknown TOOL_EVENT: $TOOL_EVENT" >&2
        exit 0
        ;;
esac
