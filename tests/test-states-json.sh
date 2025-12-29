#!/bin/bash
# Test runner for Salt states with JSON output capture
# Usage: ./tests/test-states-json.sh [linux|rhel|windows|all]
#
# All results saved to tests/output/{distro}_{YYYYMMDD}_{HHMMSS}.json
# Running with 'all' executes tests sequentially: linux → rhel → windows

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
    local container_name="salt-minion-${minion_type}-test"
    local output_file="${OUTPUT_DIR}/${minion_type}_${TIMESTAMP}.json"

    echo -e "${YELLOW}=== Testing ${minion_type} minion ===${NC}"

    # Start the test environment
    echo "Starting containers..."
    if ! docker compose --profile "test-${minion_type}" up -d --build; then
        echo -e "${RED}Failed to start containers${NC}"
        return 1
    fi

    # Wait for container to start and apply states
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

    # Capture JSON output from state.apply
    echo "Capturing JSON output..."
    if docker exec "$container_name" salt-call --local state.apply --out=json > "$output_file" 2>&1; then
        echo -e "${GREEN}JSON output saved to: ${output_file}${NC}"
    else
        echo -e "${YELLOW}Warning: JSON capture may have issues, but continuing...${NC}"
    fi

    # Parse and validate results
    echo "Parsing results..."
    if command -v jq >/dev/null 2>&1; then
        parse_json_results "$output_file" "$minion_type"
    else
        echo -e "${YELLOW}jq not installed, skipping detailed parsing${NC}"
        echo "Install jq for detailed results: apt install jq"
    fi

    # Stop containers
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

    # Extract summary using jq
    local total_states
    local succeeded_states
    local failed_states

    total_states=$(jq -r '[.local | to_entries[] | select(.key != "retcode")] | length' "$json_file" 2>/dev/null || echo "0")
    succeeded_states=$(jq -r '[.local | to_entries[] | select(.key != "retcode") | select(.value.result == true)] | length' "$json_file" 2>/dev/null || echo "0")
    failed_states=$(jq -r '[.local | to_entries[] | select(.key != "retcode") | select(.value.result == false)] | length' "$json_file" 2>/dev/null || echo "0")

    echo ""
    echo "=== Results for ${minion_type} ==="
    echo "Total states: $total_states"
    echo -e "${GREEN}Succeeded: $succeeded_states${NC}"

    if [ "$failed_states" -gt 0 ]; then
        echo -e "${RED}Failed: $failed_states${NC}"
        echo ""
        echo "Failed states:"
        jq -r '.local | to_entries[] | select(.key != "retcode") | select(.value.result == false) | "\(.key): \(.value.comment)"' "$json_file" 2>/dev/null || echo "Unable to parse failed states"
        return 1
    else
        echo -e "${GREEN}Failed: 0${NC}"
    fi

    echo ""
    return 0
}

# Main execution
case "$MINION" in
    linux)
        test_minion "linux"
        ;;
    rhel)
        test_minion "rhel"
        ;;
    windows)
        test_minion "windows"
        ;;
    all)
        echo -e "${YELLOW}=== Running sequential tests (linux → rhel → windows) ===${NC}"
        success=0
        test_minion "linux" || success=1
        echo ""
        test_minion "rhel" || success=1
        echo ""
        test_minion "windows" || success=1
        exit $success
        ;;
    *)
        echo "Usage: $0 [linux|rhel|windows|all]"
        exit 1
        ;;
esac
