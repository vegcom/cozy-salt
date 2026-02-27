"""
Docker container management for Salt state testing.

Handles container lifecycle via docker-compose profiles.
"""

import logging
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


@dataclass
class ContainerConfig:
  """Configuration for a test container."""

  profile: str
  container_name: str
  service_name: str
  timeout_seconds: int = 600
  poll_interval: int = 2


# Predefined container configurations matching docker-compose.yaml
CONTAINER_CONFIGS = {
  "ubuntu": ContainerConfig(
    profile="test-ubuntu",
    container_name="salt-minion-ubuntu-test",
    service_name="ubuntu",
  ),
  "rhel": ContainerConfig(
    profile="test-rhel",
    container_name="salt-minion-rhel-test",
    service_name="rhel",
  ),
  "windows": ContainerConfig(
    profile="test-windows",
    container_name="salt-minion-windows-test",
    service_name="windows",
    timeout_seconds=900,  # Windows needs more time
  ),
}


class ContainerError(Exception):
  """Raised when container operations fail."""

  pass


class ContainerManager:
  """
  Manages Docker containers for Salt state testing.

  Uses docker-compose profiles to start/stop containers and
  monitors logs for state completion.
  """

  def __init__(self, project_root: Optional[Path] = None):
    """
    Initialize ContainerManager.

    Args:
        project_root: Path to project root (contains docker-compose.yaml).
                     Auto-detected if not provided.
    """
    if project_root is None:
      # Find project root by looking for docker-compose.yaml
      current = Path(__file__).resolve()
      for parent in current.parents:
        if (parent / "docker-compose.yaml").exists():
          project_root = parent
          break
      if project_root is None:
        raise ContainerError("Could not find project root with docker-compose.yaml")

    self.project_root = Path(project_root)
    self._active_profile: Optional[str] = None

  def _run_compose(self, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    """Run a docker-compose command."""
    cmd = ["docker", "compose", *args]
    logger.debug(f"Running: {' '.join(cmd)}")

    result = subprocess.run(
      cmd,
      cwd=self.project_root,
      capture_output=True,
      text=True,
    )

    if check and result.returncode != 0:
      raise ContainerError(f"docker-compose failed: {result.stderr or result.stdout}")

    return result

  def _run_docker(self, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    """Run a docker command."""
    cmd = ["docker", *args]
    logger.debug(f"Running: {' '.join(cmd)}")

    result = subprocess.run(
      cmd,
      capture_output=True,
      text=True,
    )

    if check and result.returncode != 0:
      raise ContainerError(f"docker command failed: {result.stderr or result.stdout}")

    return result

  def start_containers(self, config: ContainerConfig, build: bool = True) -> None:
    """
    Start containers for testing.

    Args:
        config: Container configuration to use.
        build: Whether to rebuild images before starting.
    """
    logger.info(f"Starting containers with profile: {config.profile}")

    args = ["--profile", config.profile, "up", "-d"]
    if build:
      args.append("--build")

    self._run_compose(*args)
    self._active_profile = config.profile

  def stop_containers(self, config: ContainerConfig) -> None:
    """Stop and remove containers."""
    logger.info(f"Stopping containers with profile: {config.profile}")
    self._run_compose("--profile", config.profile, "down")
    self._active_profile = None

  def is_container_running(self, container_name: str) -> bool:
    """Check if a container is running."""
    result = self._run_docker(
      "ps",
      "--filter",
      f"name={container_name}",
      "--filter",
      "status=running",
      "--format",
      "{{.Names}}",
      check=False,
    )
    return container_name in result.stdout

  def get_container_logs(self, container_name: str) -> str:
    """Get logs from a container."""
    result = self._run_docker("logs", container_name, check=False)
    return result.stdout + result.stderr

  def wait_for_highstate(self, config: ContainerConfig) -> bool:
    """
    Wait for highstate to complete in container logs.

    Args:
        config: Container configuration.

    Returns:
        True if highstate completed, False if timeout.

    Raises:
        ContainerError: If container exits prematurely.
    """
    logger.info(f"Waiting for highstate completion (max {config.timeout_seconds}s)...")

    elapsed = 0
    while elapsed < config.timeout_seconds:
      # Check if container is still running
      if not self.is_container_running(config.container_name):
        logs = self.get_container_logs(config.container_name)
        raise ContainerError(
          f"Container {config.container_name} exited prematurely.\nLogs:\n{logs}"
        )

      # Check for completion marker in logs
      if "Highstate complete" in self.get_container_logs(config.container_name):
        logger.info("Highstate completed successfully")
        return True

      time.sleep(config.poll_interval)
      elapsed += config.poll_interval

    logger.warning(f"Timeout after {config.timeout_seconds}s waiting for highstate")
    return False

  def exec_salt_call(
    self, container_name: str, output_format: str = "json"
  ) -> subprocess.CompletedProcess:
    """
    Execute salt-call state.highstate in container.

    Args:
        container_name: Name of the container.
        output_format: Output format (json, yaml, etc).

    Returns:
        CompletedProcess with stdout/stderr.
    """
    logger.info(f"Executing salt-call in {container_name}")

    # Don't check=True because salt-call may return non-zero on failed states
    return self._run_docker(
      "exec",
      container_name,
      "salt-call",
      "state.highstate",
      f"--out={output_format}",
      check=False,
    )

  def run_test_cycle(self, distro: str, build: bool = True) -> str:
    """
    Run a complete test cycle for a distro.

    Args:
        distro: Distribution name (ubuntu, rhel, windows).
        build: Whether to rebuild images.

    Returns:
        JSON output from salt-call state.highstate.

    Raises:
        ContainerError: If any step fails.
    """
    if distro not in CONTAINER_CONFIGS:
      raise ContainerError(
        f"Unknown distro: {distro}. Valid: {list(CONTAINER_CONFIGS.keys())}"
      )

    config = CONTAINER_CONFIGS[distro]

    try:
      # Start containers
      self.start_containers(config, build=build)

      # Wait for highstate to complete
      if not self.wait_for_highstate(config):
        logs = self.get_container_logs(config.container_name)
        raise ContainerError(f"Timeout waiting for highstate.\nLogs:\n{logs}")

      # Capture JSON output (salt-call may write JSON to stderr or mix both)
      result = self.exec_salt_call(config.container_name, output_format="json")
      combined = result.stdout + result.stderr
      logger.debug(f"salt-call output ({len(combined)} bytes): {combined[:500]!r}")

      return combined

    finally:
      # Dump master logs before teardown (essential for CI debugging)
      master_logs = self._run_docker("logs", "salt", check=False)
      all_logs = master_logs.stdout + master_logs.stderr
      if all_logs.strip():
        logger.info("=== Salt master logs ===\n%s", all_logs[-3000:])
      # Dump minion logs too
      minion_logs = self._run_docker("logs", config.container_name, check=False)
      minion_out = minion_logs.stdout + minion_logs.stderr
      if minion_out.strip():
        logger.info(
          "=== Minion logs (%s) ===\n%s", config.container_name, minion_out[-3000:]
        )
      self.stop_containers(config)
