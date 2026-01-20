# Salt Minion Enrollment Library
# Distro-specific installers for onedir bootstrap

from . import arch, debian, rhel, windows

__all__ = ["arch", "debian", "rhel", "windows"]
