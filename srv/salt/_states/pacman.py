# -*- coding: utf-8 -*-
"""
Salt state module for pacman package management with clean environment.

:maintainer: cozy-salt
:maturity: production
:platform: Arch Linux

Uses sanitized environment to prevent user shell pollution.
Unlike yay, pacman CAN run as root.

Usage in states:
    system_packages:
      pacman.installed:
        - pkgs:
          - base-devel
          - git

    single_package:
      pacman.installed:
        - name: neovim

    removed_package:
      pacman.removed:
        - name: unwanted-pkg
"""

import logging

log = logging.getLogger(__name__)


def installed(name=None, pkgs=None, runas=None, refresh=False, **kwargs):
    """
    Ensure packages are installed using pacman.

    Args:
        name: Single package name (state ID or explicit name)
        pkgs: List of package names to install
        runas: Optional user to run as
        refresh: Whether to refresh package database first

    Returns:
        dict: State result with name, result, changes, comment

    Example:
        system_packages:
          pacman.installed:
            - pkgs:
              - base-devel
              - git
              - vim

        single_package:
          pacman.installed:
            - name: htop
    """
    ret = {
        "name": name if name else "pacman.installed",
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

    # Check current state
    to_install = []
    already_installed = []

    for pkg in packages:
        if __salt__["pacman.is_installed"](pkg, runas=runas):
            already_installed.append(pkg)
        else:
            to_install.append(pkg)

    # Test mode - just report what would happen
    if __opts__["test"]:
        if not to_install:
            ret["comment"] = f"All {len(packages)} package(s) already installed"
        else:
            ret["result"] = None
            ret["comment"] = f"Would install: {', '.join(to_install)}"
            if already_installed:
                ret["comment"] += f". Already installed: {', '.join(already_installed)}"
        return ret

    # Nothing to do
    if not to_install:
        ret["comment"] = f"All {len(packages)} package(s) already installed"
        return ret

    # Install packages
    result = __salt__["pacman.installed"](
        pkgs=to_install,
        runas=runas,
        refresh=refresh,
    )

    ret["changes"] = result.get("changes", {})
    ret["result"] = result.get("result", False)

    # Build comment
    comments = []
    installed_count = len(ret["changes"])
    if installed_count:
        comments.append(f"Installed {installed_count} package(s)")
    if already_installed:
        comments.append(f"{len(already_installed)} already installed")
    if not result.get("result", False):
        comments.append(f"Errors: {result.get('comment', 'unknown')}")

    ret["comment"] = ". ".join(comments) if comments else result.get("comment", "")

    return ret


def removed(name, runas=None, **kwargs):
    """
    Ensure a package is removed using pacman.

    Args:
        name: Package name to remove
        runas: Optional user to run as

    Returns:
        dict: State result with name, result, changes, comment

    Example:
        unwanted_package:
          pacman.removed:
            - name: some-package
    """
    ret = {
        "name": name,
        "result": True,
        "changes": {},
        "comment": "",
    }

    # Check if installed
    if not __salt__["pacman.is_installed"](name, runas=runas):
        ret["comment"] = f"Package {name} is not installed"
        return ret

    # Test mode
    if __opts__["test"]:
        ret["result"] = None
        ret["comment"] = f"Would remove: {name}"
        return ret

    # Remove package
    result = __salt__["pacman.remove"](name, runas=runas)

    ret["result"] = result.get("success", False)
    ret["changes"] = result.get("changes", {})
    ret["comment"] = result.get("comment", "")

    return ret


def uptodate(name="pacman.uptodate", runas=None, refresh=True, **kwargs):
    """
    Ensure all packages are up to date.

    Args:
        name: State name (defaults to pacman.uptodate)
        runas: Optional user to run as
        refresh: Whether to refresh package database (default: True)

    Returns:
        dict: State result

    Example:
        system_upgraded:
          pacman.uptodate
    """
    ret = {
        "name": name,
        "result": True,
        "changes": {},
        "comment": "",
    }

    # Test mode
    if __opts__["test"]:
        ret["result"] = None
        ret["comment"] = "Would upgrade all packages"
        return ret

    # Run upgrade
    result = __salt__["pacman.upgrade"](runas=runas, refresh=refresh)

    ret["result"] = result.get("success", False)

    if ret["result"]:
        stdout = result.get("stdout", "")
        if "there is nothing to do" in stdout.lower():
            ret["comment"] = "All packages are up to date"
        else:
            ret["changes"]["upgraded"] = "System packages upgraded"
            ret["comment"] = "Packages upgraded successfully"
    else:
        ret["comment"] = f"Upgrade failed: {result.get('stderr', 'unknown error')}"

    return ret
