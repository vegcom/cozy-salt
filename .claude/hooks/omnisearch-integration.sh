#!/bin/bash
# Omnisearch Integration Hook
# Auto-query knowledge graph before major codebase changes
# Enforces CLAUDE.md rule: "check DeepWiki + Omnisearch FIRST"

set -euo pipefail

# Extract tool name and relevant search terms from input
TOOL_NAME="${TOOL_NAME:-unknown}"
TOOL_INPUT="${TOOL_INPUT:-{}}"

# Helper: Extract search terms from tool input
extract_search_terms() {
    local input="$1"
    local terms=""

    # Extract file paths
    local file_path=$(echo "$input" | jq -r '.file_path // .path // empty' 2>/dev/null || echo "")
    if [[ -n "$file_path" ]]; then
        # Get basename and key parts of path
        local basename=$(basename "$file_path" 2>/dev/null || echo "")
        local dirname=$(dirname "$file_path" 2>/dev/null || echo "")
        terms="$basename $(basename "$dirname" 2>/dev/null || echo "")"
    fi

    # Extract content patterns (for Edit/Write operations)
    local old_string=$(echo "$input" | jq -r '.old_string // empty' 2>/dev/null || echo "")
    local new_string=$(echo "$input" | jq -r '.new_string // empty' 2>/dev/null || echo "")
    local content=$(echo "$input" | jq -r '.content // empty' 2>/dev/null || echo "")

    # Extract key identifiers (function names, state names, etc)
    for text in "$old_string" "$new_string" "$content"; do
        if [[ -n "$text" ]]; then
            # Extract SaltStack state names (id declarations)
            local state_ids=$(echo "$text" | grep -oP '^\s*[a-zA-Z0-9_\-\.]+:' 2>/dev/null | tr -d ':' || echo "")
            terms="$terms $state_ids"

            # Extract salt:// references
            local salt_refs=$(echo "$text" | grep -oP 'salt://[a-zA-Z0-9_/\.\-]+' 2>/dev/null || echo "")
            terms="$terms $salt_refs"

            # Extract include statements
            local includes=$(echo "$text" | grep -oP 'include:\s*-\s*[a-zA-Z0-9_\.\-]+' 2>/dev/null | cut -d- -f2 || echo "")
            terms="$terms $includes"
        fi
    done

    # Extract bash command patterns
    local command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null || echo "")
    if [[ "$command" =~ (mv|rm|cp|rename|delete|refactor) ]]; then
        # Extract paths from destructive commands
        local paths=$(echo "$command" | grep -oP '[a-zA-Z0-9_/\.\-]+\.(sls|sh|yaml|yml|conf)' || echo "")
        terms="$terms $paths"
    fi

    # Clean and deduplicate
    echo "$terms" | tr ' ' '\n' | grep -v '^$' | sort -u | head -10 | tr '\n' ' '
}

# Helper: Query Omnisearch via MCP (simulated - actual implementation would use MCP client)
query_omnisearch() {
    local search_term="$1"

    # Note: In production, this would use the MCP protocol to call:
    # mcp__memory__search_nodes with query="$search_term"
    # For now, we'll create a marker that Claude can act on

    echo "🔍 Omnisearch query needed: '$search_term'" >&2

    # Return suggestion to check knowledge graph
    cat <<EOF
{
  "suggestion": "Before proceeding, check Omnisearch for: $search_term",
  "reason": "CLAUDE.md requires checking existing patterns first",
  "action": "Query knowledge graph for context"
}
EOF
}

# Main hook logic
main() {
    # Only trigger on operations that modify codebase structure
    case "$TOOL_NAME" in
        Edit|Write|Bash)
            local search_terms=$(extract_search_terms "$TOOL_INPUT")
            local is_destructive=false

            # File moves/deletes in Bash commands
            if [[ "$TOOL_NAME" == "Bash" ]]; then
                local cmd=$(echo "$TOOL_INPUT" | jq -r '.command // empty' 2>/dev/null)
                if echo "$cmd" | grep -qE '\b(mv|rm|cp|rename|delete|refactor)\b'; then
                    is_destructive=true
                fi
            fi

            if [[ -n "$search_terms" || "$is_destructive" == "true" ]]; then

                # Large edits (potential refactoring)
                if [[ "$TOOL_NAME" == "Edit" ]]; then
                    local old_lines=$(echo "$TOOL_INPUT" | jq -r '.old_string // empty' | wc -l)
                    if [[ $old_lines -gt 10 ]]; then
                        is_destructive=true
                    fi
                fi

                # New file creation in critical areas
                if [[ "$TOOL_NAME" == "Write" ]]; then
                    local file_path=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
                    if [[ "$file_path" =~ (srv/salt|srv/pillar|provisioning|scripts) ]]; then
                        is_destructive=true
                    fi
                fi

                if [[ "$is_destructive" == "true" ]]; then
                    echo "⚠️  Major change detected. Recommended Omnisearch queries:" >&2
                    for term in $search_terms; do
                        query_omnisearch "$term" >&2
                    done
                    echo "" >&2
                    echo "💡 Use: mcp__memory__search_nodes to query knowledge graph" >&2
                    echo "📋 Or grep: grep -Hnr '$search_terms' srv/salt/ srv/pillar/ provisioning/" >&2
                    echo "" >&2

                    # Don't block operation, just warn
                    # Exit 0 = allow with context
                    exit 0
                fi
            fi
            ;;
    esac

    # All other operations: pass through
    exit 0
}

main "$@"
