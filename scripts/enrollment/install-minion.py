#!/usr/bin/env python3
"""Cross-platform Salt Minion installer.

Usage:
    python install-minion.py --master MASTER --minion-id ID --roles ROLE1,ROLE2

Automatically detects OS and uses the appropriate installer:
    - Arch Linux: onedir bootstrap
    - Debian/Ubuntu/Kali: onedir bootstrap
    - RHEL/CentOS/Rocky: onedir bootstrap
    - Windows: official installer exe
"""

from __future__ import annotations

import argparse
import sys
from typing import TYPE_CHECKING

from lib.common import check_root, detect_os, is_salt_installed

if TYPE_CHECKING:
  from typing import Callable


def get_installer() -> tuple[Callable, str]:
  """Get the appropriate installer for the current OS.

  Returns:
      Tuple of (install_function, os_name)
  """
  os_family, distro_id, _ = detect_os()

  if os_family == "Windows":
    from lib.windows import install

    return install, "Windows"

  if os_family == "Arch":
    from lib.arch import install

    return install, f"Arch ({distro_id})"

  if os_family == "Debian":
    from lib.debian import install

    return install, f"Debian ({distro_id})"

  if os_family == "RedHat":
    from lib.rhel import install

    return install, f"RHEL ({distro_id})"

  # Fallback: try to detect from is_supported() checks
  from lib import arch, debian, rhel, windows

  if windows.is_supported():
    return windows.install, "Windows"
  if arch.is_supported():
    return arch.install, "Arch Linux"
  if debian.is_supported():
    return debian.install, "Debian/Ubuntu"
  if rhel.is_supported():
    return rhel.install, "RHEL/CentOS"

  print(f"Error: Unsupported OS family: {os_family} ({distro_id})")
  sys.exit(1)


def parse_args() -> argparse.Namespace:
  """Parse command line arguments."""
  parser = argparse.ArgumentParser(
    description="Install and configure Salt Minion",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=__doc__,
  )
  parser.add_argument(
    "--master",
    required=True,
    help="Salt master hostname or IP",
  )
  parser.add_argument(
    "--minion-id",
    required=True,
    help="Minion ID (hostname for this minion)",
  )
  parser.add_argument(
    "--roles",
    required=True,
    help="Comma-separated list of roles (e.g., workstation,developer)",
  )
  parser.add_argument(
    "--force",
    action="store_true",
    help="Force reinstall even if Salt is already installed",
  )
  return parser.parse_args()


def main() -> int:
  """Main entry point."""
  args = parse_args()

  # Parse roles
  roles = [r.strip() for r in args.roles.split(",") if r.strip()]
  if not roles:
    print("Error: At least one role is required")
    return 1

  # Check privileges
  check_root()

  # Check if already installed
  if is_salt_installed() and not args.force:
    print("Salt is already installed. Use --force to reconfigure.")
    print("Reconfiguring existing installation...")
    # TODO: Just update config without reinstalling
    # For now, continue with full install

  # Get installer for this OS
  install_fn, os_name = get_installer()

  print(f"Detected OS: {os_name}")
  print(f"Master: {args.master}")
  print(f"Minion ID: {args.minion_id}")
  print(f"Roles: {', '.join(roles)}")
  print()

  try:
    install_fn(args.master, args.minion_id, roles)
    print()
    print("=" * 50)
    print("Salt Minion installation complete!")
    print()
    print("Next steps:")
    print("  1. Accept the minion key on the master:")
    print(f"     salt-key -a {args.minion_id}")
    print("  2. Test connectivity:")
    print(f"     salt '{args.minion_id}' test.ping")
    print("  3. Apply highstate:")
    print(f"     salt '{args.minion_id}' state.highstate")
    print("=" * 50)
    return 0
  except Exception as e:
    print(f"Error during installation: {e}")
    return 1


if __name__ == "__main__":
  sys.exit(main())
