#!/bin/bash
# Test runner for Salt states with JSON output capture
# Usage: ./tests/test-states-json.sh [ubuntu|linux|apt|rhel|windows|ci|all]
#
# Modes:
#   ubuntu/linux/apt - Test single Ubuntu minion
#   rhel            - Test single RHEL minion
#   windows         - Test single Windows minion
#   ci              - CI mode: shared master, parallel minions (ubuntu + rhel)
#   all             - Same as ci mode
#
# All results saved to tests/output/{distro}_{YYYYMMDD}_{HHMMSS}.json

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

MODE="${1:-ci}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="${PROJECT_ROOT}/tests/output"
mkdir -p "$OUTPUT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

normalize_distro() {
    local distro="$1"
    case "$distro" in
        linux|apt) echo "ubuntu" ;;
        *) echo "$distro" ;;
    esac
}

start_master() {
    echo -e "${BLUE}=== Starting salt-master ===${NC}"

    if ! docker compose up -d --build salt-master; then
        echo -e "${RED}Failed to start salt-master${NC}"
        return 1
    fi

    echo "Waiting for salt-master to be healthy..."
    local wait=0
    while [ $wait -lt 90 ]; do
        if docker inspect --format='{{.State.Health.Status}}' salt-master 2>/dev/null | grep -q "healthy"; then
            echo -e "${GREEN}Salt master is healthy${NC}"
            return 0
        fi
        sleep 2
        wait=$((wait + 2))
    done

    echo -e "${RED}Salt master failed to become healthy${NC}"
    docker logs salt-master
    return 1
}

start_minion() {
    local distro="$1"
    distro=$(normalize_distro "$distro")

    echo -e "${YELLOW}Starting salt-minion-${distro}...${NC}"
    if ! docker compose --profile "test-${distro}" up -d --build "salt-minion-${distro}"; then
        echo -e "${RED}Failed to start salt-minion-${distro}${NC}"
        return 1
    fi
    return 0
}

wait_for_highstate() {
    local distro="$1"
    local timeout="${2:-600}"
    distro=$(normalize_distro "$distro")

    local container_name="salt-minion-${distro}-test"
    local elapsed=0

    echo -e "${YELLOW}Waiting for ${distro} highstate (max ${timeout}s)...${NC}"

    while [ $elapsed -lt $timeout ]; do
        if docker logs "$container_name" 2>&1 | grep -q "Highstate complete"; then
            echo -e "${GREEN}${distro}: Highstate complete${NC}"
            return 0
        fi

        if ! docker ps --filter "name=${container_name}" --filter "status=running" | grep -q "$container_name"; then
            echo -e "${RED}${distro}: Container exited prematurely${NC}"
            docker logs "$container_name" 2>&1 | tail -50
            return 1
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    echo -e "${RED}${distro}: Timeout waiting for highstate${NC}"
    docker logs "$container_name" 2>&1 | tail -50
    return 1
}

capture_results() {
    local distro="$1"
    distro=$(normalize_distro "$distro")

    local container_name="salt-minion-${distro}-test"
    local output_file="${OUTPUT_DIR}/${distro}_${TIMESTAMP}.json"

    echo -e "${BLUE}Capturing ${distro} results...${NC}"

    # Capture JSON (may return non-zero if some states failed)
    docker exec "$container_name" salt-call state.highstate --out=json > "$output_file" 2>&1 || true

    if [ -f "$output_file" ] && grep -q "^{" "$output_file"; then
        echo -e "${GREEN}${distro}: JSON saved to ${output_file}${NC}"
        parse_json_results "$output_file" "$distro"
        return $?
    else
        echo -e "${RED}${distro}: Failed to capture JSON output${NC}"
        return 1
    fi
}

parse_json_results() {
    local json_file="$1"
    local distro="$2"

    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${YELLOW}jq not installed, skipping detailed parsing${NC}"
        return 0
    fi

    local json_content
    json_content=$(sed -n '/^{/,$p' "$json_file")
    if [ -z "$json_content" ]; then
        echo -e "${RED}No valid JSON found in output${NC}"
        return 1
    fi

    local total succeeded failed
    total=$(echo "$json_content" | jq '.local | length' 2>/dev/null || echo "0")
    succeeded=$(echo "$json_content" | jq '[.local[] | select(.result == true)] | length' 2>/dev/null || echo "0")
    failed=$(echo "$json_content" | jq '[.local[] | select(.result == false)] | length' 2>/dev/null || echo "0")

    echo ""
    echo "=== ${distro} Results ==="
    echo "Total: $total | Passed: $succeeded | Failed: $failed"

    if [ "$failed" -gt 0 ]; then
        echo -e "${RED}Failed states:${NC}"
        echo "$json_content" | jq -r '.local[] | select(.result == false) | "  - \(.__id__): \(.comment)"' 2>/dev/null || true
        return 1
    fi
    return 0
}

cleanup() {
    echo -e "${BLUE}=== Cleanup ===${NC}"
    docker compose --profile test-ubuntu --profile test-rhel --profile test-windows down 2>/dev/null || true
}

# ============================================================================
# Single Distro Test (legacy mode)
# ============================================================================

test_single() {
    local distro="$1"
    distro=$(normalize_distro "$distro")

    echo -e "${YELLOW}=== Testing ${distro} (single mode) ===${NC}"

    start_master || return 1
    start_minion "$distro" || { cleanup; return 1; }

    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"

    wait_for_highstate "$distro" || { cleanup; return 1; }
    capture_results "$distro"
    local result=$?

    cleanup
    return $result
}

# ============================================================================
# CI Mode: Shared master, parallel minions
# ============================================================================

test_ci() {
    local distros=("ubuntu" "rhel")
    local results=()

    echo -e "${BLUE}=== CI Mode: Testing ${distros[*]} with shared master ===${NC}"
    echo ""

    # Start master once
    if ! start_master; then
        cleanup
        return 1
    fi

    # Start all minions in parallel
    echo -e "${BLUE}=== Starting all minions ===${NC}"
    for distro in "${distros[@]}"; do
        start_minion "$distro" || results+=("$distro:start_failed")
    done

    echo ""
    echo "Running containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    echo ""

    # Wait for all highstates (in parallel via background jobs)
    echo -e "${BLUE}=== Waiting for highstates ===${NC}"
    declare -A pids
    for distro in "${distros[@]}"; do
        (wait_for_highstate "$distro" 600) &
        pids[$distro]=$!
    done

    # Collect wait results
    for distro in "${distros[@]}"; do
        if ! wait "${pids[$distro]}"; then
            results+=("$distro:highstate_failed")
        fi
    done

    # Capture results from each
    echo ""
    echo -e "${BLUE}=== Capturing results ===${NC}"
    for distro in "${distros[@]}"; do
        if ! capture_results "$distro"; then
            results+=("$distro:capture_failed")
        fi
    done

    # Summary
    echo ""
    echo -e "${BLUE}=== Summary ===${NC}"
    if [ ${#results[@]} -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        cleanup
        return 0
    else
        echo -e "${RED}Failures:${NC}"
        for r in "${results[@]}"; do
            echo -e "  ${RED}- $r${NC}"
        done
        cleanup
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

trap cleanup EXIT

case "$MODE" in
    ubuntu|linux|apt)
        test_single "ubuntu"
        exit $?
        ;;
    rhel)
        test_single "rhel"
        exit $?
        ;;
    windows)
        test_single "windows"
        exit $?
        ;;
    ci|all)
        test_ci
        exit $?
        ;;
    *)
        echo "Usage: $0 [ubuntu|linux|apt|rhel|windows|ci|all]"
        echo ""
        echo "Modes:"
        echo "  ubuntu/linux/apt  Test Ubuntu minion only"
        echo "  rhel              Test RHEL minion only"
        echo "  windows           Test Windows minion only"
        echo "  ci/all            CI mode: shared master, parallel ubuntu+rhel"
        exit 1
        ;;
esac
