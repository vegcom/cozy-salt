"""
Linting tests for cozy-salt project.

Runs shellcheck, yamllint, and salt-lint on project files.
Tests skip gracefully if tools are not installed.
"""

import subprocess
import shutil
from pathlib import Path

import pytest


# Project root detection
PROJECT_ROOT = Path(__file__).parent.parent.resolve()


def tool_available(tool_name: str) -> bool:
    """Check if a command-line tool is available."""
    return shutil.which(tool_name) is not None


# Tool availability flags
HAS_SHELLCHECK = tool_available("shellcheck")
HAS_YAMLLINT = tool_available("yamllint")
HAS_SALTLINT = tool_available("salt-lint")


def collect_shell_scripts() -> list[Path]:
    """Collect all .sh files from scripts/ and provisioning/ directories."""
    scripts = []
    search_dirs = [
        PROJECT_ROOT / "scripts",
        PROJECT_ROOT / "provisioning",
    ]
    
    for search_dir in search_dirs:
        if search_dir.exists():
            scripts.extend(search_dir.rglob("*.sh"))
    
    return sorted(scripts)


def collect_sls_files() -> list[Path]:
    """Collect all .sls files from srv/salt/ directory."""
    salt_dir = PROJECT_ROOT / "srv" / "salt"
    if not salt_dir.exists():
        return []
    return sorted(salt_dir.rglob("*.sls"))


def collect_yaml_files() -> list[Path]:
    """Collect all YAML files from srv/ directory (pillar configs, etc)."""
    srv_dir = PROJECT_ROOT / "srv"
    if not srv_dir.exists():
        return []
    
    yaml_files = []
    for ext in ("*.yml", "*.yaml"):
        yaml_files.extend(srv_dir.rglob(ext))
    
    # Also include .sls files since they're YAML with Jinja
    yaml_files.extend(srv_dir.rglob("*.sls"))
    
    return sorted(set(yaml_files))


# Collect files once at module load
SHELL_SCRIPTS = collect_shell_scripts()
SLS_FILES = collect_sls_files()
YAML_FILES = collect_yaml_files()


# --- Shellcheck Tests ---

@pytest.mark.skipif(not HAS_SHELLCHECK, reason="shellcheck not installed")
@pytest.mark.skipif(not SHELL_SCRIPTS, reason="no shell scripts found")
@pytest.mark.parametrize(
    "script_path",
    SHELL_SCRIPTS,
    ids=lambda p: str(p.relative_to(PROJECT_ROOT)),
)
def test_shellcheck(script_path: Path):
    """Run shellcheck on a shell script."""
    result = subprocess.run(
        ["shellcheck", "-f", "gcc", str(script_path)],
        capture_output=True,
        text=True,
    )
    
    if result.returncode != 0:
        # Format error message with file path and shellcheck output
        rel_path = script_path.relative_to(PROJECT_ROOT)
        pytest.fail(
            f"shellcheck failed for {rel_path}:\n{result.stdout}{result.stderr}"
        )


# --- Yamllint Tests ---

@pytest.mark.skipif(not HAS_YAMLLINT, reason="yamllint not installed")
@pytest.mark.skipif(not YAML_FILES, reason="no YAML files found")
@pytest.mark.parametrize(
    "yaml_path",
    YAML_FILES,
    ids=lambda p: str(p.relative_to(PROJECT_ROOT)),
)
def test_yamllint(yaml_path: Path):
    """Run yamllint on a YAML file."""
    # Check for project yamllint config
    config_file = PROJECT_ROOT / ".yamllint.yml"
    
    cmd = ["yamllint", "-f", "parsable"]
    if config_file.exists():
        cmd.extend(["-c", str(config_file)])
    cmd.append(str(yaml_path))
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        rel_path = yaml_path.relative_to(PROJECT_ROOT)
        pytest.fail(
            f"yamllint failed for {rel_path}:\n{result.stdout}{result.stderr}"
        )


# --- Salt-lint Tests ---

@pytest.mark.skipif(not HAS_SALTLINT, reason="salt-lint not installed")
@pytest.mark.skipif(not SLS_FILES, reason="no SLS files found")
@pytest.mark.parametrize(
    "sls_path",
    SLS_FILES,
    ids=lambda p: str(p.relative_to(PROJECT_ROOT)),
)
def test_saltlint(sls_path: Path):
    """Run salt-lint on a Salt state file."""
    # Check for project salt-lint config
    config_file = PROJECT_ROOT / ".salt-lint"
    
    cmd = ["salt-lint"]
    if config_file.exists():
        cmd.extend(["-c", str(config_file)])
    cmd.append(str(sls_path))
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        rel_path = sls_path.relative_to(PROJECT_ROOT)
        pytest.fail(
            f"salt-lint failed for {rel_path}:\n{result.stdout}{result.stderr}"
        )


# --- Summary Tests (optional, for quick checks) ---

@pytest.mark.skipif(not HAS_SHELLCHECK, reason="shellcheck not installed")
def test_shellcheck_installed():
    """Verify shellcheck is available and report version."""
    result = subprocess.run(
        ["shellcheck", "--version"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, "shellcheck not working properly"


@pytest.mark.skipif(not HAS_YAMLLINT, reason="yamllint not installed")
def test_yamllint_installed():
    """Verify yamllint is available and report version."""
    result = subprocess.run(
        ["yamllint", "--version"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, "yamllint not working properly"


@pytest.mark.skipif(not HAS_SALTLINT, reason="salt-lint not installed")
def test_saltlint_installed():
    """Verify salt-lint is available and report version."""
    result = subprocess.run(
        ["salt-lint", "--version"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, "salt-lint not working properly"
