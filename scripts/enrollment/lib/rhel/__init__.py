"""RHEL/CentOS/Rocky/Fedora Salt Minion installer using onedir bootstrap."""

from __future__ import annotations

import subprocess
from pathlib import Path

from ..common import download_bootstrap_script, run_command, write_minion_config

SALT_CONFIG_DIR = Path("/etc/salt")


def install(master: str, minion_id: str, roles: list[str]) -> None:
  """Install Salt Minion on RHEL-family using onedir bootstrap.

  Uses onedir for consistency across all distros.
  """
  print("=== Installing Salt Minion on RHEL/CentOS/Rocky (onedir) ===")

  # Install prerequisites
  run_command(["yum", "install", "-y", "curl", "ca-certificates"], check=False)

  # Download bootstrap script
  bootstrap = download_bootstrap_script()

  try:
    # Make executable
    bootstrap.chmod(0o755)

    # Run bootstrap with onedir flag
    run_command(["sh", str(bootstrap), "-P", "onedir"])
  finally:
    # Cleanup
    bootstrap.unlink(missing_ok=True)

  # Write minion configuration
  write_minion_config(SALT_CONFIG_DIR, master, minion_id, roles)

  # Enable and start service
  print("Enabling and starting salt-minion service...")
  run_command(["systemctl", "enable", "salt-minion"])
  run_command(["systemctl", "restart", "salt-minion"])

  # Quick connectivity test
  try:
    run_command(
      ["salt-call", "test.ping", "-l", "warning"],
      check=False,
    )
  except subprocess.SubprocessError:
    pass  # May fail if master hasn't accepted key yet


def is_supported() -> bool:
  """Check if this installer supports the current system."""
  os_release = Path("/etc/os-release")
  if not os_release.exists():
    return False

  content = os_release.read_text().lower()
  return any(
    d in content for d in ["rhel", "centos", "rocky", "almalinux", "fedora", "oracle"]
  )
