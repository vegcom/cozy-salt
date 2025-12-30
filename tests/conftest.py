"""
pytest configuration and fixtures for cozy-salt tests.

Provides Docker container fixtures and Salt result parsing utilities.
"""

import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Generator

import pytest

from tests.fixtures.docker import CONTAINER_CONFIGS, ContainerManager
from tests.lib.salt_results import ParsedResults, SaltResultParser

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def pytest_configure(config: pytest.Config) -> None:
    """Register custom markers."""
    config.addinivalue_line("markers", "ubuntu: Ubuntu/Debian state tests")
    config.addinivalue_line("markers", "rhel: RHEL/Rocky state tests")
    config.addinivalue_line("markers", "windows: Windows state tests")
    config.addinivalue_line("markers", "slow: marks tests as slow")
    config.addinivalue_line("markers", "integration: integration tests requiring Docker")


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Get the project root directory."""
    # Find docker-compose.yaml to locate project root
    current = Path(__file__).resolve()
    for parent in current.parents:
        if (parent / "docker-compose.yaml").exists():
            return parent
    raise RuntimeError("Could not find project root")


@pytest.fixture(scope="session")
def output_dir(project_root: Path) -> Path:
    """Get or create the test output directory."""
    output = project_root / "tests" / "output"
    output.mkdir(exist_ok=True)
    return output


@pytest.fixture(scope="session")
def container_manager(project_root: Path) -> ContainerManager:
    """Create a container manager for the session."""
    return ContainerManager(project_root)


@pytest.fixture(scope="session")
def result_parser() -> type[SaltResultParser]:
    """Provide the SaltResultParser class."""
    return SaltResultParser


def _run_distro_test(
    container_manager: ContainerManager,
    output_dir: Path,
    distro: str,
    build: bool = True,
) -> ParsedResults:
    """
    Run state tests for a specific distro and return parsed results.

    Args:
        container_manager: Container manager fixture.
        output_dir: Directory for JSON output files.
        distro: Distribution name.
        build: Whether to rebuild containers.

    Returns:
        Parsed results from highstate run.
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = output_dir / f"{distro}_{timestamp}.json"

    logger.info(f"Running {distro} state tests...")

    # Run the test cycle
    raw_output = container_manager.run_test_cycle(distro, build=build)

    # Save raw output
    with open(output_file, "w") as f:
        f.write(raw_output)
    logger.info(f"Saved output to {output_file}")

    # Parse results
    results = SaltResultParser.parse(raw_output)

    logger.info(f"Results: {results.succeeded}/{results.total} succeeded")

    return results


@pytest.fixture(scope="module")
def ubuntu_results(
    container_manager: ContainerManager,
    output_dir: Path,
) -> ParsedResults:
    """Run Ubuntu state tests and return results."""
    return _run_distro_test(container_manager, output_dir, "ubuntu")


@pytest.fixture(scope="module")
def rhel_results(
    container_manager: ContainerManager,
    output_dir: Path,
) -> ParsedResults:
    """Run RHEL state tests and return results."""
    return _run_distro_test(container_manager, output_dir, "rhel")


@pytest.fixture(scope="module")
def windows_results(
    container_manager: ContainerManager,
    output_dir: Path,
) -> ParsedResults:
    """Run Windows state tests and return results."""
    return _run_distro_test(container_manager, output_dir, "windows")


# Environment variable to skip container rebuild
@pytest.fixture(scope="session")
def skip_build() -> bool:
    """Check if container rebuild should be skipped."""
    return os.environ.get("PYTEST_SKIP_BUILD", "").lower() in ("1", "true", "yes")
