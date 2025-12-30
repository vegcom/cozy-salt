#!/bin/bash
# Test runner for Salt states with JSON output capture
# Usage: ./tests/test-states-json.sh [ubuntu|linux|apt|rhel|windows|all]
#
# All results saved to tests/output/{distro}_{YYYYMMDD}_{HHMMSS}.json
# Running with 'all' executes tests sequentially: ubuntu → rhel → windows
# ubuntu, linux, apt are aliases for the same apt-based Ubuntu 24.04 test

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

MINION="${1:-all}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="${PROJECT_ROOT}/tests/output"
mkdir -p "$OUTPUT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_minion() {
    local minion_type="$1"
    local service_name="${minion_type}"
    local output_label="${minion_type}"

    if [ "$minion_type" = "linux" ] || [ "$minion_type" = "apt" ]; then
        service_name="ubuntu"
        output_label="ubuntu"
    fi

    local container_name="salt-minion-${service_name}-test"
    local output_file="${OUTPUT_DIR}/${output_label}_${TIMESTAMP}.json"

    echo -e "${YELLOW}=== Testing ${minion_type} minion ===${NC}"

    echo "Starting containers..."
    if ! docker compose --profile "test-${service_name}" up -d --build; then
        echo -e "${RED}Failed to start containers${NC}"
        return 1
    fi

    echo "Waiting for state application (max 120s)..."
    local timeout=120
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        if docker logs "$container_name" 2>&1 | grep -q "Highstate complete"; then
            echo -e "${GREEN}State application completed!${NC}"
            break
        fi

        if ! docker ps --filter "name=${container_name}" --filter "status=running" | grep -q "$container_name"; then
            echo -e "${RED}Container exited prematurely${NC}"
            docker logs "$container_name"
            docker compose --profile "test-${minion_type}" down
            return 1
        fi

        sleep 2
        elapsed=$((elapsed + 2))
    done

    if [ $elapsed -ge $timeout ]; then
        echo -e "${RED}Timeout waiting for state application${NC}"
        docker logs "$container_name"
        docker compose --profile "test-${minion_type}" down
        return 1
    fi

    echo "Capturing JSON output..."
    if docker exec "$container_name" salt-call state.highstate --out=json > "$output_file" 2>&1; then
        echo -e "${GREEN}JSON output saved to: ${output_file}${NC}"
    else
        echo -e "${RED}Failed to capture JSON output${NC}"
        return 1
    fi

    # Parse and validate results
    echo "Parsing results..."
    if command -v jq >/dev/null 2>&1; then
        parse_json_results "$output_file" "$minion_type"
    else
        echo -e "${YELLOW}jq not installed, skipping detailed parsing${NC}"
        echo "Install jq for detailed results: apt install jq"
    fi

    echo "Stopping containers..."
    docker compose --profile "test-${minion_type}" down

    return 0
}

parse_json_results() {
    local json_file="$1"
    local minion_type="$2"

    if [ ! -f "$json_file" ]; then
        echo -e "${RED}JSON file not found${NC}"
        return 1
    fi

    local json_content=$(sed -n '/^{/,$p' "$json_file")
    if [ -z "$json_content" ]; then
        echo -e "${RED}No valid JSON found in output${NC}"
        return 1
    fi

    local total_states
    local succeeded_states
    local failed_states

    total_states=$(echo "$json_content" | jq '.local | length' 2>/dev/null || echo "0")
    succeeded_states=$(echo "$json_content" | jq '[.local[] | select(.result == true)] | length' 2>/dev/null || echo "0")
    failed_states=$(echo "$json_content" | jq '[.local[] | select(.result == false)] | length' 2>/dev/null || echo "0")

    echo ""
    echo "=== Results for ${minion_type} ==="
    echo "Total states: $total_states"
    echo -e "${GREEN}Succeeded: $succeeded_states${NC}"

    if [ "$failed_states" -gt 0 ]; then
        echo -e "${RED}Failed: $failed_states${NC}"
        echo ""
        echo "Failed states:"
        echo "$json_content" | jq -r '.local[] | select(.result == false) | "\(.__id__): \(.comment)"' 2>/dev/null || echo "Unable to parse failed states"
        return 1
    else
        echo -e "${GREEN}Failed: 0${NC}"
    fi

    echo ""
    return 0
}

# Main execution
case "$MINION" in
    ubuntu|linux|apt)
        test_minion "ubuntu"
        ;;
    rhel)
        test_minion "rhel"
        ;;
    windows)
        test_minion "windows"
        ;;
    all)
        echo -e "${YELLOW}=== Running sequential tests (ubuntu → rhel → windows) ===${NC}"
        success=0
        test_minion "ubuntu" || success=1
        echo ""
        test_minion "rhel" || success=1
        echo ""
        test_minion "windows" || success=1
        exit $success
        ;;
    *)
        echo "Usage: $0 [ubuntu|linux|apt|rhel|windows|all]"
        exit 1
        ;;
esac
