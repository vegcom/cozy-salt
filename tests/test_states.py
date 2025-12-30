"""
Salt state integration tests.

Tests Salt highstate execution across Ubuntu, RHEL, and Windows containers.
Uses pytest markers for selective test execution:

    pytest -m ubuntu      # Run only Ubuntu tests
    pytest -m rhel        # Run only RHEL tests
    pytest -m windows     # Run only Windows tests
    pytest -m integration # Run all integration tests

Usage:
    pytest tests/test_states.py -v
    pytest tests/test_states.py -v -m ubuntu
    PYTEST_SKIP_BUILD=1 pytest tests/test_states.py -v  # Skip container rebuild
"""

import pytest

from tests.lib.salt_results import ParsedResults, SaltResultParser


# =============================================================================
# Ubuntu Tests
# =============================================================================


@pytest.mark.ubuntu
@pytest.mark.integration
@pytest.mark.slow
class TestUbuntuStates:
    """Test Salt states on Ubuntu/Debian."""

    def test_highstate_succeeds(self, ubuntu_results: ParsedResults) -> None:
        """All Ubuntu highstate states should succeed."""
        if not ubuntu_results.all_succeeded:
            failure_msg = SaltResultParser.format_failures(ubuntu_results)
            pytest.fail(f"Ubuntu highstate had failures:\n{failure_msg}")

    def test_has_states(self, ubuntu_results: ParsedResults) -> None:
        """Ubuntu should have at least one state executed."""
        assert ubuntu_results.total > 0, "No states were executed"

    def test_state_count(self, ubuntu_results: ParsedResults) -> None:
        """Report state execution counts."""
        # This test always passes but reports metrics
        print(f"\nUbuntu state summary:")
        print(f"  Total:     {ubuntu_results.total}")
        print(f"  Succeeded: {ubuntu_results.succeeded}")
        print(f"  Failed:    {ubuntu_results.failed}")


# =============================================================================
# RHEL Tests
# =============================================================================


@pytest.mark.rhel
@pytest.mark.integration
@pytest.mark.slow
class TestRHELStates:
    """Test Salt states on RHEL/Rocky Linux."""

    def test_highstate_succeeds(self, rhel_results: ParsedResults) -> None:
        """All RHEL highstate states should succeed."""
        if not rhel_results.all_succeeded:
            failure_msg = SaltResultParser.format_failures(rhel_results)
            pytest.fail(f"RHEL highstate had failures:\n{failure_msg}")

    def test_has_states(self, rhel_results: ParsedResults) -> None:
        """RHEL should have at least one state executed."""
        assert rhel_results.total > 0, "No states were executed"

    def test_state_count(self, rhel_results: ParsedResults) -> None:
        """Report state execution counts."""
        print(f"\nRHEL state summary:")
        print(f"  Total:     {rhel_results.total}")
        print(f"  Succeeded: {rhel_results.succeeded}")
        print(f"  Failed:    {rhel_results.failed}")


# =============================================================================
# Windows Tests
# =============================================================================


@pytest.mark.windows
@pytest.mark.integration
@pytest.mark.slow
class TestWindowsStates:
    """Test Salt states on Windows."""

    def test_highstate_succeeds(self, windows_results: ParsedResults) -> None:
        """All Windows highstate states should succeed."""
        if not windows_results.all_succeeded:
            failure_msg = SaltResultParser.format_failures(windows_results)
            pytest.fail(f"Windows highstate had failures:\n{failure_msg}")

    def test_has_states(self, windows_results: ParsedResults) -> None:
        """Windows should have at least one state executed."""
        assert windows_results.total > 0, "No states were executed"

    def test_state_count(self, windows_results: ParsedResults) -> None:
        """Report state execution counts."""
        print(f"\nWindows state summary:")
        print(f"  Total:     {windows_results.total}")
        print(f"  Succeeded: {windows_results.succeeded}")
        print(f"  Failed:    {windows_results.failed}")


# =============================================================================
# Unit Tests for Parser (run without Docker)
# =============================================================================


class TestSaltResultParser:
    """Unit tests for the Salt result parser."""

    SAMPLE_OUTPUT = """{
        "local": {
            "pkg_|-install_vim_|-vim_|-installed": {
                "result": true,
                "comment": "Package vim is already installed",
                "name": "vim",
                "changes": {},
                "duration": 50.123
            },
            "file_|-config_file_|-/etc/myconfig_|-managed": {
                "result": false,
                "comment": "Source file not found",
                "name": "/etc/myconfig",
                "changes": {},
                "duration": 10.5
            },
            "retcode": 0
        }
    }"""

    def test_parse_valid_json(self) -> None:
        """Parser handles valid Salt JSON output."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)
        assert results.total == 2
        assert results.succeeded == 1
        assert results.failed == 1

    def test_parse_extracts_state_details(self) -> None:
        """Parser extracts state details correctly."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)

        vim_state = results.get_state("vim")
        assert vim_state is not None
        assert vim_state.succeeded
        assert vim_state.name == "vim"

    def test_parse_identifies_failures(self) -> None:
        """Parser correctly identifies failed states."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)

        failed = results.failed_states
        assert len(failed) == 1
        assert failed[0].name == "/etc/myconfig"
        assert "not found" in failed[0].comment

    def test_parse_skips_metadata(self) -> None:
        """Parser skips metadata keys like retcode."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)
        # Should have 2 states, not 3 (retcode is metadata)
        assert results.total == 2

    def test_parse_handles_prefix_garbage(self) -> None:
        """Parser handles non-JSON prefix in output."""
        garbage = "local:\n    some log output\n" + self.SAMPLE_OUTPUT
        results = SaltResultParser.parse(garbage)
        assert results.total == 2

    def test_parse_raises_on_invalid_json(self) -> None:
        """Parser raises ValueError on invalid JSON."""
        with pytest.raises(ValueError, match="No JSON object found"):
            SaltResultParser.parse("not json at all")

    def test_parse_raises_on_missing_local(self) -> None:
        """Parser handles missing 'local' key gracefully."""
        results = SaltResultParser.parse('{"other": {}}')
        assert results.total == 0

    def test_format_failures_empty(self) -> None:
        """format_failures handles no failures."""
        results = SaltResultParser.parse('{"local": {}}')
        output = SaltResultParser.format_failures(results)
        assert output == "No failures"

    def test_format_failures_detailed(self) -> None:
        """format_failures provides detailed failure info."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)
        output = SaltResultParser.format_failures(results)
        assert "Failed states (1/2)" in output
        assert "/etc/myconfig" in output
        assert "not found" in output

    def test_all_succeeded_property(self) -> None:
        """all_succeeded is False when any state fails."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)
        assert not results.all_succeeded

    def test_get_states_pattern_matching(self) -> None:
        """get_states returns all matching states."""
        results = SaltResultParser.parse(self.SAMPLE_OUTPUT)
        # Both states contain underscores
        states = results.get_states(r"_\|-")
        assert len(states) == 2
