"""
Custom grain: maps managed usernames to their home directory paths.
Computed once per salt run, cached in grains — avoids repeated cmd.run in state renders.
Uses __salt__ for path resolution so logic stays consistent with windows.sls macros.
"""

import logging
import os

log = logging.getLogger(__name__)


def _get_windows_home(username):
  """Resolve home path via ProfileList registry using __salt__['cmd.run']."""
  base = username.split(".")[0]
  cmd = (
    f'(Get-ItemProperty "HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion'
    f"\\ProfileList\\$((Get-LocalUser -Name '{base}').SID)\").ProfileImagePath"
    f'.Replace("\\\\", "/")'
  )
  try:
    path = __salt__["cmd.run"](cmd, shell="powershell").strip()  # noqa: F821
    return path or None
  except Exception as e:
    log.warning("user_homes: failed to resolve home for %s: %s", username, e)
    return None


def user_homes():
  """
  Grain: returns dict mapping username -> home path for all managed_users.

  Usage in states:
      {% set home = grains.get('user_homes', {}).get(username, '/home/' + username) %}
  """
  homes = {}
  is_windows = os.name == "nt"

  try:
    managed_users = __salt__["pillar.get"]("managed_users", [], merge=True)  # noqa: F821
  except Exception as e:
    log.warning("user_homes: could not get managed_users from pillar: %s", e)
    return {"user_homes": homes}

  for username in managed_users:
    if is_windows:
      path = _get_windows_home(username)
      if path:
        homes[username] = path
        base = username.split(".")[0]
        if base != username:
          homes[base] = path
    else:
      homes[username] = f"/home/{username}"

  return {"user_homes": homes}
