"""
Salt state result parsing and validation.

Parses JSON output from salt-call state.highstate and provides
structured access to results for pytest assertions.
"""

import json
import re
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class StateResult:
  """Result of a single Salt state execution."""

  state_id: str
  result: Optional[bool]
  comment: str = ""
  changes: dict = field(default_factory=dict)
  duration: float = 0.0
  name: str = ""
  state_type: str = ""

  @property
  def succeeded(self) -> bool:
    """True if state succeeded."""
    return self.result is True

  @property
  def failed(self) -> bool:
    """True if state failed."""
    return self.result is False

  def __repr__(self) -> str:
    status = "OK" if self.succeeded else "FAIL" if self.failed else "SKIP"
    return f"<StateResult {self.state_id} [{status}]>"


@dataclass
class ParsedResults:
  """Aggregated results from a Salt highstate run."""

  states: list[StateResult] = field(default_factory=list)
  raw_data: dict = field(default_factory=dict)

  @property
  def total(self) -> int:
    """Total number of states."""
    return len(self.states)

  @property
  def succeeded(self) -> int:
    """Number of succeeded states."""
    return sum(1 for s in self.states if s.succeeded)

  @property
  def failed(self) -> int:
    """Number of failed states."""
    return sum(1 for s in self.states if s.failed)

  @property
  def failed_states(self) -> list[StateResult]:
    """List of failed states."""
    return [s for s in self.states if s.failed]

  @property
  def all_succeeded(self) -> bool:
    """True if all states succeeded."""
    return self.failed == 0 and self.total > 0

  def get_state(self, pattern: str) -> Optional[StateResult]:
    """Get first state matching pattern (regex)."""
    regex = re.compile(pattern)
    for state in self.states:
      if regex.search(state.state_id):
        return state
    return None

  def get_states(self, pattern: str) -> list[StateResult]:
    """Get all states matching pattern (regex)."""
    regex = re.compile(pattern)
    return [s for s in self.states if regex.search(s.state_id)]


class SaltResultParser:
  """
  Parser for Salt state.highstate JSON output.

  Handles the nested structure of Salt JSON output and
  extracts individual state results for validation.
  """

  # Metadata keys to skip when parsing states
  METADATA_KEYS = {"retcode", "out", "jid"}

  @staticmethod
  def extract_json(raw_output: str) -> str:
    """
    Extract JSON from raw output that may contain non-JSON prefix.

    Salt output sometimes includes log messages before the JSON.
    This finds the first '{' and extracts from there.
    """
    # Find first JSON object start
    json_start = raw_output.find("{")
    if json_start == -1:
      raise ValueError("No JSON object found in output")

    return raw_output[json_start:]

  @classmethod
  def parse(cls, raw_output: str) -> ParsedResults:
    """
    Parse raw salt-call output into structured results.

    Args:
        raw_output: Raw stdout from salt-call --out=json.

    Returns:
        ParsedResults with individual state results.

    Raises:
        ValueError: If output is not valid JSON.
        KeyError: If expected structure is missing.
    """
    # Extract JSON portion
    json_str = cls.extract_json(raw_output)

    try:
      data = json.loads(json_str)
    except json.JSONDecodeError as e:
      raise ValueError(f"Invalid JSON: {e}")

    if not isinstance(data, dict):
      raise ValueError(f"Expected dict, got {type(data).__name__}")

    # Salt output is nested under 'local' key
    local_data = data.get("local", {})

    if not isinstance(local_data, dict):
      raise ValueError(f"Expected dict for 'local', got {type(local_data).__name__}")

    states = []

    for state_id, state_data in local_data.items():
      # Skip metadata keys
      if state_id in cls.METADATA_KEYS:
        continue

      # Skip non-dict entries
      if not isinstance(state_data, dict):
        continue

      state = StateResult(
        state_id=state_id,
        result=state_data.get("result"),
        comment=state_data.get("comment", ""),
        changes=state_data.get("changes", {}),
        duration=state_data.get("duration", 0.0),
        name=state_data.get("name", ""),
        state_type=state_data.get("__sls__", ""),
      )
      states.append(state)

    return ParsedResults(states=states, raw_data=data)

  @classmethod
  def parse_file(cls, filepath: str) -> ParsedResults:
    """
    Parse a JSON file containing salt-call output.

    Args:
        filepath: Path to JSON file.

    Returns:
        ParsedResults with individual state results.
    """
    with open(filepath, "r") as f:
      return cls.parse(f.read())

  @staticmethod
  def format_failures(results: ParsedResults) -> str:
    """
    Format failed states for error output.

    Args:
        results: Parsed results.

    Returns:
        Human-readable failure summary.
    """
    if not results.failed_states:
      return "No failures"

    lines = [f"Failed states ({results.failed}/{results.total}):"]

    for state in results.failed_states:
      lines.append(f"\n  State: {state.state_id}")
      lines.append(f"    Comment: {state.comment}")
      if state.changes:
        changes_str = json.dumps(state.changes, indent=6)
        lines.append(f"    Changes: {changes_str}")
      lines.append(f"    Duration: {state.duration}ms")

    return "\n".join(lines)
