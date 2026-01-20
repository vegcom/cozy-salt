"""Windows Salt Minion installer."""

from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from ..common import download_file, run_command, write_minion_config

SALT_CONFIG_DIR = Path(r"C:\salt\conf")
SALT_VERSION = "3007.1"

# Download URL for Windows Salt installer
SALT_WINDOWS_URL = (
  f"https://packages.broadcom.com/artifactory/saltproject-generic/windows/"
  f"{SALT_VERSION}/Salt-Minion-{SALT_VERSION}-Py3-AMD64-Setup.exe"
)


def install(master: str, minion_id: str, roles: list[str]) -> None:
  """Install Salt Minion on Windows.

  Downloads and runs the official Salt installer executable.
  """
  print("=== Installing Salt Minion on Windows ===")

  salt_exe = Path(r"C:\salt\salt-minion.exe")

  if not salt_exe.exists():
    # Download installer
    with tempfile.NamedTemporaryFile(suffix=".exe", delete=False) as tmp:
      installer_path = Path(tmp.name)

    try:
      download_file(SALT_WINDOWS_URL, installer_path)

      # Run installer silently
      print("Running Salt installer...")
      install_args = [
        str(installer_path),
        "/S",
        f"/master={master}",
        f"/minion-name={minion_id}",
      ]
      run_command(install_args)
    finally:
      installer_path.unlink(missing_ok=True)

  # Write minion configuration
  write_minion_config(SALT_CONFIG_DIR, master, minion_id, roles)

  # Start service
  print("Starting salt-minion service...")
  run_command(["net", "start", "salt-minion"], check=False)

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
  import platform

  return platform.system() == "Windows"
