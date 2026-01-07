#!/usr/bin/env python3
"""
Parse Salt state.apply JSON output for CI/CD validation.
Returns exit code 0 if all states succeeded, 1 if any failed.

Usage:
    python3 parse-state-results.py <json-file>
    cat output.json | python3 parse-state-results.py -
"""

import json
import sys
from pathlib import Path


def parse_state_results(data):
    """Parse Salt state JSON output and return summary."""
    if not isinstance(data, dict):
        return {"error": "Invalid JSON structure"}

    # Salt output is nested under 'local' key
    local_data = data.get("local", {})

    total = 0
    succeeded = 0
    failed = 0
    failed_states = []

    for state_id, state_data in local_data.items():
        # Skip metadata keys
        if state_id in ["retcode", "out"]:
            continue

        if not isinstance(state_data, dict):
            continue

        total += 1
        result = state_data.get("result")

        if result is True:
            succeeded += 1
        elif result is False:
            failed += 1
            failed_states.append({
                "id": state_id,
                "comment": state_data.get("comment", "No comment"),
                "changes": state_data.get("changes", {}),
                "duration": state_data.get("duration", 0)
            })

    return {
        "total": total,
        "succeeded": succeeded,
        "failed": failed,
        "failed_states": failed_states
    }


def main():
    if len(sys.argv) < 2:
        print("Usage: parse-state-results.py <json-file|->", file=sys.stderr)
        sys.exit(2)

    input_file = sys.argv[1]

    try:
        if input_file == "-":
            data = json.load(sys.stdin)
        else:
            with open(input_file, 'r') as f:
                data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON: {e}", file=sys.stderr)
        sys.exit(2)
    except FileNotFoundError:
        print(f"ERROR: File not found: {input_file}", file=sys.stderr)
        sys.exit(2)

    results = parse_state_results(data)

    if "error" in results:
        print(f"ERROR: {results['error']}", file=sys.stderr)
        sys.exit(2)

    # Print summary
    print(f"=== Salt State Results ===")
    print(f"Total states: {results['total']}")
    print(f"Succeeded: {results['succeeded']}")
    print(f"Failed: {results['failed']}")

    if results['failed'] > 0:
        print("\n=== Failed States ===")
        for state in results['failed_states']:
            print(f"\nState: {state['id']}")
            print(f"  Comment: {state['comment']}")
            if state['changes']:
                print(f"  Changes: {json.dumps(state['changes'], indent=4)}")
            print(f"  Duration: {state['duration']}ms")

        sys.exit(1)
    else:
        print("\nAll states succeeded!")
        sys.exit(0)


if __name__ == "__main__":
    main()
