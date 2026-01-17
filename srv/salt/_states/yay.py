# -*- coding: utf-8 -*-
"""
Salt state module for yay (AUR helper) package management.

:maintainer: cozy-salt
:maturity: production
:platform: Arch Linux

yay CANNOT run as root - all operations require runas parameter.

Usage in states:
    core_packages:
      yay.installed:
        - pkgs:
          - firefox
          - chromium
        - runas: admin

    single_package:
      yay.installed:
        - name: neovim
        - runas: admin

    removed_package:
      yay.removed:
        - name: unwanted-pkg
        - runas: admin
"""

import logging

log = logging.getLogger(__name__)


def installed(name=None, pkgs=None, runas=None, refresh=False, **kwargs):
    """
    Ensure packages are installed using yay.

    Args:
        name: Single package name (state ID or explicit name)
        pkgs: List of package names to install
        runas: User to run as (REQUIRED - yay cannot run as root)
        refresh: Whether to refresh package database first

    Returns:
        dict: State result with name, result, changes, comment

    Example:
        core_utils_packages:
          yay.installed:
            - pkgs:
              - firefox
              - chromium
              - neovim
            - runas: admin

        single_package:
          yay.installed:
            - name: htop
            - runas: admin
    """
    ret = {
        "name": name if name else "yay.installed",
        "result": True,
        "changes": {},
        "comment": "",
    }

    # Validate runas - this is non-negotiable for yay
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

    # Check current state
    to_install = []
    already_installed = []

    for pkg in packages:
        if __salt__["yay.is_installed"](pkg, runas=runas):
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
    result = __salt__["yay.installed"](
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
    Ensure a package is removed using yay.

    Args:
        name: Package name to remove
        runas: User to run as (REQUIRED - yay cannot run as root)

    Returns:
        dict: State result with name, result, changes, comment

    Example:
        unwanted_package:
          yay.removed:
            - name: some-package
            - runas: admin
    """
    ret = {
        "name": name,
        "result": True,
        "changes": {},
        "comment": "",
    }

    # Validate runas
    if not runas:
        ret["result"] = False
        ret["comment"] = "runas parameter is required - yay cannot run as root"
        return ret

    # Check if installed
    if not __salt__["yay.is_installed"](name, runas=runas):
        ret["comment"] = f"Package {name} is not installed"
        return ret

    # Test mode
    if __opts__["test"]:
        ret["result"] = None
        ret["comment"] = f"Would remove: {name}"
        return ret

    # Remove package
    result = __salt__["yay.remove"](name, runas=runas)

    ret["result"] = result.get("success", False)
    ret["changes"] = result.get("changes", {})
    ret["comment"] = result.get("comment", "")

    return ret


def uptodate(name="yay.uptodate", runas=None, refresh=True, **kwargs):
    """
    Ensure all packages are up to date.

    Args:
        name: State name (defaults to yay.uptodate)
        runas: User to run as (REQUIRED)
        refresh: Whether to refresh package database (default: True)

    Returns:
        dict: State result

    Example:
        system_upgraded:
          yay.uptodate:
            - runas: admin
    """
    ret = {
        "name": name,
        "result": True,
        "changes": {},
        "comment": "",
    }

    # Validate runas
    if not runas:
        ret["result"] = False
        ret["comment"] = "runas parameter is required - yay cannot run as root"
        return ret

    # Test mode
    if __opts__["test"]:
        ret["result"] = None
        ret["comment"] = "Would upgrade all packages"
        return ret

    # Run upgrade
    result = __salt__["yay.upgrade"](runas=runas, refresh=refresh)

    ret["result"] = result.get("success", False)

    if ret["result"]:
        # Check if anything was upgraded by looking at stdout
        stdout = result.get("stdout", "")
        if "there is nothing to do" in stdout.lower():
            ret["comment"] = "All packages are up to date"
        else:
            ret["changes"]["upgraded"] = "System packages upgraded"
            ret["comment"] = "Packages upgraded successfully"
    else:
        ret["comment"] = f"Upgrade failed: {result.get('stderr', 'unknown error')}"

    return ret
