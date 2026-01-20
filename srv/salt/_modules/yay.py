# -*- coding: utf-8 -*-
"""
Salt execution module for yay (AUR helper) package management.

:maintainer: cozy-salt
:maturity: production
:platform: Arch Linux

yay CANNOT run as root - all operations require runas parameter.
Uses sanitized environment to prevent user shell pollution during AUR builds.

Usage from states:
    core_packages:
      yay.installed:
        - pkgs:
          - package1
          - package2
        - runas: admin
"""

import logging

log = logging.getLogger(__name__)

__virtualname__ = "yay"


def __virtual__():
  """
  Only load on Arch Linux systems where yay is available.
  """
  if __grains__.get("os") not in ("Arch ARM", "Arch"):
    if __grains__.get("os_family") != "Arch":
      return (False, "yay module only works on Arch Linux")

  # Check if yay binary exists
  if not __salt__["cmd.which"]("yay"):
    return (False, "yay binary not found - bootstrap yay first")

  return __virtualname__


def _clean_env(runas):
  """
  Build a sanitized environment for package operations.

  Strips user shell pollution (custom PATH, env vars) that can
  interfere with AUR builds and package compilation.

  Args:
      runas: Username for home directory paths

  Returns:
      dict: Clean environment variables
  """
  return {
    "HOME": f"/home/{runas}",
    "USER": runas,
    "LOGNAME": runas,
    "LANG": "C.UTF-8",
    "LC_ALL": "C.UTF-8",
    "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
    "XDG_CACHE_HOME": f"/home/{runas}/.cache",
    "XDG_CONFIG_HOME": f"/home/{runas}/.config",
    "XDG_DATA_HOME": f"/home/{runas}/.local/share",
    # Prevent gpg issues in builds
    "GNUPGHOME": f"/home/{runas}/.gnupg",
  }


def _run_yay(cmd, runas, **kwargs):
  """
  Execute a yay command as the specified user with clean environment.

  yay cannot run as root, so runas is mandatory.
  Uses sanitized env to prevent build pollution from user shell config.

  Args:
      cmd: The yay command to run
      runas: Username to run as (required)
      **kwargs: Additional args passed to cmd.run_all

  Returns:
      dict: Command result with stdout, stderr, retcode
  """
  if not runas:
    return {
      "retcode": 1,
      "stdout": "",
      "stderr": "yay cannot run as root - runas parameter is required",
    }

  result = __salt__["cmd.run_all"](
    cmd,
    runas=runas,
    python_shell=True,
    env=_clean_env(runas),
    **kwargs,
  )

  return result


def is_installed(name, runas=None):
  """
  Check if a package is installed via pacman/yay.

  Args:
      name: Package name to check
      runas: User to run as (optional for query, but good practice)

  Returns:
      bool: True if installed, False otherwise

  CLI Example:
      salt '*' yay.is_installed firefox runas=admin
  """
  # yay -Q queries local database, works as any user
  # but we still use runas for consistency
  user = runas or "nobody"

  result = __salt__["cmd.run_all"](
    f"yay -Q {name}",
    runas=user,
    python_shell=True,
    ignore_retcode=True,
  )

  return result["retcode"] == 0


def list_installed(runas=None):
  """
  List all installed packages.

  Args:
      runas: User to run as

  Returns:
      dict: Package names mapped to versions

  CLI Example:
      salt '*' yay.list_installed runas=admin
  """
  user = runas or "nobody"

  result = __salt__["cmd.run_all"](
    "yay -Q",
    runas=user,
    python_shell=True,
  )

  if result["retcode"] != 0:
    return {}

  packages = {}
  for line in result["stdout"].strip().split("\n"):
    if line:
      parts = line.split()
      if len(parts) >= 2:
        packages[parts[0]] = parts[1]

  return packages


def install(name, runas=None, refresh=False):
  """
  Install a single package using yay.

  Uses --needed to skip if already installed.
  Uses --noconfirm for non-interactive operation.

  Args:
      name: Package name to install
      runas: User to run as (REQUIRED)
      refresh: Whether to refresh package database first

  Returns:
      dict: Result with success, changes, and output

  CLI Example:
      salt '*' yay.install firefox runas=admin
  """
  if not runas:
    return {
      "success": False,
      "changes": {},
      "comment": "runas parameter is required - yay cannot run as root",
    }

  # Check if already installed
  if is_installed(name, runas=runas):
    return {
      "success": True,
      "changes": {},
      "comment": f"Package {name} is already installed",
    }

  # Build command
  cmd = "yay -S --needed --noconfirm"
  if refresh:
    cmd = "yay -Sy --needed --noconfirm"

  cmd = f"{cmd} {name}"

  result = _run_yay(cmd, runas=runas)

  if result["retcode"] == 0:
    return {
      "success": True,
      "changes": {name: {"old": "", "new": "installed"}},
      "comment": f"Successfully installed {name}",
      "stdout": result["stdout"],
      "stderr": result["stderr"],
    }
  else:
    return {
      "success": False,
      "changes": {},
      "comment": f"Failed to install {name}",
      "stdout": result["stdout"],
      "stderr": result["stderr"],
    }


def installed(name=None, pkgs=None, runas=None, refresh=False, **kwargs):
  """
  Ensure packages are installed using yay.

  This is the main function called by states.
  Supports both single package and list of packages.

  Args:
      name: Single package name (for simple states)
      pkgs: List of package names
      runas: User to run as (REQUIRED - yay cannot run as root)
      refresh: Whether to refresh package database first

  Returns:
      dict: State-compatible result with name, result, changes, comment

  State Example:
      core_packages:
        yay.installed:
          - pkgs:
            - firefox
            - chromium
          - runas: vegcom

      single_package:
        yay.installed:
          - name: neovim
          - runas: vegcom
  """
  ret = {
    "name": name or "yay.installed",
    "result": True,
    "changes": {},
    "comment": "",
  }

  # Validate runas
  if not runas:
    ret["result"] = False
    ret["comment"] = "runas parameter is required - yay cannot run as root"
    return ret

  # Build package list
  packages = []
  if pkgs:
    packages = list(pkgs)
  elif name:
    packages = [name]

  if not packages:
    ret["comment"] = "No packages specified"
    return ret

  # Track results
  installed_pkgs = []
  already_installed = []
  failed_pkgs = []
  errors = []

  # Check which packages need installation
  to_install = []
  for pkg in packages:
    if is_installed(pkg, runas=runas):
      already_installed.append(pkg)
    else:
      to_install.append(pkg)

  # If nothing to install, we're done
  if not to_install:
    ret["comment"] = f"All {len(already_installed)} package(s) already installed"
    return ret

  # Install all needed packages in one yay call (more efficient)
  cmd = "yay -S --needed --noconfirm"
  if refresh:
    cmd = "yay -Sy --needed --noconfirm"

  pkg_str = " ".join(to_install)
  cmd = f"{cmd} {pkg_str}"

  result = _run_yay(cmd, runas=runas, timeout=600)

  if result["retcode"] == 0:
    # Verify what actually got installed
    for pkg in to_install:
      if is_installed(pkg, runas=runas):
        installed_pkgs.append(pkg)
        ret["changes"][pkg] = {"old": "", "new": "installed"}
      else:
        # Package didn't install despite success retcode (weird but possible)
        failed_pkgs.append(pkg)
  else:
    # Batch install failed - try individually to see what works
    log.warning(f"Batch install failed, trying packages individually: {to_install}")

    for pkg in to_install:
      single_result = install(pkg, runas=runas, refresh=refresh)
      if single_result["success"]:
        installed_pkgs.append(pkg)
        ret["changes"][pkg] = {"old": "", "new": "installed"}
      else:
        failed_pkgs.append(pkg)
        errors.append(f"{pkg}: {single_result.get('stderr', 'unknown error')}")

  # Build summary comment
  comments = []
  if installed_pkgs:
    comments.append(f"Installed: {', '.join(installed_pkgs)}")
  if already_installed:
    comments.append(f"Already installed: {', '.join(already_installed)}")
  if failed_pkgs:
    comments.append(f"Failed: {', '.join(failed_pkgs)}")
    ret["result"] = False

  ret["comment"] = ". ".join(comments)

  # Add stdout/stderr for debugging if there were issues
  if failed_pkgs:
    if errors:
      ret["comment"] += f"\nErrors: {'; '.join(errors)}"
    elif result.get("stderr"):
      ret["comment"] += f"\nstderr: {result['stderr'][:500]}"

  return ret


def remove(name, runas=None):
  """
  Remove a package using yay.

  Args:
      name: Package name to remove
      runas: User to run as (REQUIRED)

  Returns:
      dict: Result with success, changes, and output

  CLI Example:
      salt '*' yay.remove firefox runas=admin
  """
  if not runas:
    return {
      "success": False,
      "changes": {},
      "comment": "runas parameter is required - yay cannot run as root",
    }

  # Check if installed
  if not is_installed(name, runas=runas):
    return {
      "success": True,
      "changes": {},
      "comment": f"Package {name} is not installed",
    }

  result = _run_yay(f"yay -R --noconfirm {name}", runas=runas)

  if result["retcode"] == 0:
    return {
      "success": True,
      "changes": {name: {"old": "installed", "new": ""}},
      "comment": f"Successfully removed {name}",
    }
  else:
    return {
      "success": False,
      "changes": {},
      "comment": f"Failed to remove {name}: {result['stderr']}",
    }


def upgrade(runas=None, refresh=True):
  """
  Upgrade all packages using yay.

  Args:
      runas: User to run as (REQUIRED)
      refresh: Whether to refresh package database first (default: True)

  Returns:
      dict: Result with stdout/stderr

  CLI Example:
      salt '*' yay.upgrade runas=admin
  """
  if not runas:
    return {
      "success": False,
      "comment": "runas parameter is required - yay cannot run as root",
    }

  cmd = "yay -Syu --noconfirm" if refresh else "yay -Su --noconfirm"

  result = _run_yay(cmd, runas=runas, timeout=1800)

  return {
    "success": result["retcode"] == 0,
    "stdout": result["stdout"],
    "stderr": result["stderr"],
    "retcode": result["retcode"],
  }


def search(query, runas=None):
  """
  Search for packages in repos and AUR.

  Args:
      query: Search query
      runas: User to run as

  Returns:
      list: Matching package names

  CLI Example:
      salt '*' yay.search firefox runas=admin
  """
  user = runas or "nobody"

  result = __salt__["cmd.run_all"](
    f"yay -Ss {query}",
    runas=user,
    python_shell=True,
  )

  if result["retcode"] != 0:
    return []

  # Parse yay -Ss output (package lines start with repo/name)
  packages = []
  for line in result["stdout"].split("\n"):
    if "/" in line and not line.startswith(" "):
      # Line format: "repo/package-name version (optional info)"
      parts = line.split()
      if parts:
        pkg_full = parts[0]  # repo/package
        if "/" in pkg_full:
          pkg_name = pkg_full.split("/")[1]
          packages.append(pkg_name)

  return packages


def info(name, runas=None):
  """
  Get detailed info about a package.

  Args:
      name: Package name
      runas: User to run as

  Returns:
      dict: Package information

  CLI Example:
      salt '*' yay.info firefox runas=admin
  """
  user = runas or "nobody"

  result = __salt__["cmd.run_all"](
    f"yay -Si {name}",
    runas=user,
    python_shell=True,
  )

  if result["retcode"] != 0:
    return {}

  # Parse yay -Si output
  info_dict = {}
  for line in result["stdout"].split("\n"):
    if ":" in line:
      key, _, value = line.partition(":")
      info_dict[key.strip()] = value.strip()

  return info_dict
