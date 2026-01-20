# -*- coding: utf-8 -*-
"""
Salt execution module for pacman package management with clean environment.

:maintainer: cozy-salt
:maturity: production
:platform: Arch Linux

Uses sanitized environment to prevent user shell pollution during package operations.
Unlike yay, pacman CAN run as root - but clean env is still beneficial.

Usage from states (or use Salt's built-in pkg module):
    system_packages:
      pacman.installed:
        - pkgs:
          - base-devel
          - git
"""

import logging

log = logging.getLogger(__name__)

__virtualname__ = "pacman"


def __virtual__():
    """
    Only load on Arch Linux systems.
    """
    if __grains__.get("os") not in ("Arch ARM", "Arch"):
        if __grains__.get("os_family") != "Arch":
            return (False, "pacman module only works on Arch Linux")

    # Check if pacman binary exists
    if not __salt__["cmd.which"]("pacman"):
        return (False, "pacman binary not found")

    return __virtualname__


def _clean_env(runas=None):
    """
    Build a sanitized environment for package operations.

    Strips user shell pollution (custom PATH, env vars) that can
    interfere with package operations and post-install scripts.

    Args:
        runas: Optional username for home directory paths (defaults to root)

    Returns:
        dict: Clean environment variables
    """
    if runas:
        home = f"/home/{runas}"
    else:
        home = "/root"

    return {
        "HOME": home,
        "USER": runas or "root",
        "LOGNAME": runas or "root",
        "LANG": "C.UTF-8",
        "LC_ALL": "C.UTF-8",
        "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "XDG_CACHE_HOME": f"{home}/.cache",
        "XDG_CONFIG_HOME": f"{home}/.config",
        "XDG_DATA_HOME": f"{home}/.local/share",
    }


def _run_pacman(cmd, runas=None, **kwargs):
    """
    Execute a pacman command with clean environment.

    Args:
        cmd: The pacman command to run
        runas: Optional username to run as (defaults to root)
        **kwargs: Additional args passed to cmd.run_all

    Returns:
        dict: Command result with stdout, stderr, retcode
    """
    run_kwargs = {
        "python_shell": True,
        "env": _clean_env(runas),
    }
    if runas:
        run_kwargs["runas"] = runas

    run_kwargs.update(kwargs)

    result = __salt__["cmd.run_all"](cmd, **run_kwargs)
    return result


def sync(runas=None):
    """
    Synchronize package databases.

    Args:
        runas: Optional user to run as

    Returns:
        dict: Command result

    CLI Example:
        salt '*' pacman.sync
    """
    return _run_pacman("pacman -Sy --noconfirm", runas=runas)


def is_installed(name, runas=None):
    """
    Check if a package is installed.

    Args:
        name: Package name to check
        runas: Optional user to run as

    Returns:
        bool: True if installed, False otherwise

    CLI Example:
        salt '*' pacman.is_installed firefox
    """
    result = _run_pacman(f"pacman -Q {name}", runas=runas, ignore_retcode=True)
    return result["retcode"] == 0


def list_installed(runas=None):
    """
    List all installed packages.

    Args:
        runas: Optional user to run as

    Returns:
        dict: Package names mapped to versions

    CLI Example:
        salt '*' pacman.list_installed
    """
    result = _run_pacman("pacman -Q", runas=runas)

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
    Install a single package using pacman.

    Args:
        name: Package name to install
        runas: Optional user to run as
        refresh: Whether to refresh package database first

    Returns:
        dict: Result with success, changes, and output

    CLI Example:
        salt '*' pacman.install firefox
    """
    # Check if already installed
    if is_installed(name, runas=runas):
        return {
            "success": True,
            "changes": {},
            "comment": f"Package {name} is already installed",
        }

    # Build command
    cmd = "pacman -S --needed --noconfirm"
    if refresh:
        cmd = "pacman -Sy --needed --noconfirm"

    cmd = f"{cmd} {name}"

    result = _run_pacman(cmd, runas=runas)

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
    Ensure packages are installed using pacman.

    Args:
        name: Single package name (for simple states)
        pkgs: List of package names
        runas: Optional user to run as
        refresh: Whether to refresh package database first

    Returns:
        dict: State-compatible result with name, result, changes, comment

    State Example:
        system_packages:
          pacman.installed:
            - pkgs:
              - base-devel
              - git
    """
    ret = {
        "name": name or "pacman.installed",
        "result": True,
        "changes": {},
        "comment": "",
    }

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

    # Install all needed packages in one pacman call
    cmd = "pacman -S --needed --noconfirm"
    if refresh:
        cmd = "pacman -Sy --needed --noconfirm"

    pkg_str = " ".join(to_install)
    cmd = f"{cmd} {pkg_str}"

    result = _run_pacman(cmd, runas=runas, timeout=600)

    if result["retcode"] == 0:
        # Verify what actually got installed
        for pkg in to_install:
            if is_installed(pkg, runas=runas):
                installed_pkgs.append(pkg)
                ret["changes"][pkg] = {"old": "", "new": "installed"}
            else:
                failed_pkgs.append(pkg)
    else:
        # Batch install failed - try individually
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

    if failed_pkgs:
        if errors:
            ret["comment"] += f"\nErrors: {'; '.join(errors)}"
        elif result.get("stderr"):
            ret["comment"] += f"\nstderr: {result['stderr'][:500]}"

    return ret


def remove(name, runas=None):
    """
    Remove a package using pacman.

    Args:
        name: Package name to remove
        runas: Optional user to run as

    Returns:
        dict: Result with success, changes, and output

    CLI Example:
        salt '*' pacman.remove firefox
    """
    # Check if installed
    if not is_installed(name, runas=runas):
        return {
            "success": True,
            "changes": {},
            "comment": f"Package {name} is not installed",
        }

    result = _run_pacman(f"pacman -R --noconfirm {name}", runas=runas)

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
    Upgrade all packages using pacman.

    Args:
        runas: Optional user to run as
        refresh: Whether to refresh package database first (default: True)

    Returns:
        dict: Result with stdout/stderr

    CLI Example:
        salt '*' pacman.upgrade
    """
    cmd = "pacman -Syu --noconfirm" if refresh else "pacman -Su --noconfirm"

    result = _run_pacman(cmd, runas=runas, timeout=1800)

    return {
        "success": result["retcode"] == 0,
        "stdout": result["stdout"],
        "stderr": result["stderr"],
        "retcode": result["retcode"],
    }


def search(query, runas=None):
    """
    Search for packages in repos.

    Args:
        query: Search query
        runas: Optional user to run as

    Returns:
        list: Matching package names

    CLI Example:
        salt '*' pacman.search firefox
    """
    result = _run_pacman(f"pacman -Ss {query}", runas=runas)

    if result["retcode"] != 0:
        return []

    # Parse pacman -Ss output
    packages = []
    for line in result["stdout"].split("\n"):
        if "/" in line and not line.startswith(" "):
            parts = line.split()
            if parts:
                pkg_full = parts[0]
                if "/" in pkg_full:
                    pkg_name = pkg_full.split("/")[1]
                    packages.append(pkg_name)

    return packages


def info(name, runas=None):
    """
    Get detailed info about a package.

    Args:
        name: Package name
        runas: Optional user to run as

    Returns:
        dict: Package information

    CLI Example:
        salt '*' pacman.info firefox
    """
    result = _run_pacman(f"pacman -Si {name}", runas=runas)

    if result["retcode"] != 0:
        return {}

    info_dict = {}
    for line in result["stdout"].split("\n"):
        if ":" in line:
            key, _, value = line.partition(":")
            info_dict[key.strip()] = value.strip()

    return info_dict
