"""
Custom grain for Windows winget package inventory.
Captures installed package IDs for both user and machine scope.
"""

import json
import logging
import os
import subprocess

log = logging.getLogger(__name__)

_PS_SCRIPT = """
$result = @{}
foreach ($Scope in @('user','machine')) {
  $key = if ($Scope -eq 'user') { "user-$env:USERNAME" } else { 'machine' }
  $seenSeparator = $false
  $ids = winget list --scope $Scope --source winget 2>$null | ForEach-Object {
    if (-not $seenSeparator) {
      if ($_ -match '^-{5,}$') { $seenSeparator = $true }
      return
    }
    if ($_ -match '^(?<Name>.+?)\\s{2,}(?<Id>\\S+)\\s{2,}(?<Version>\\S+)') { $Matches.Id }
  }
  $result[$key] = @($ids)
}
$result | ConvertTo-Json -Depth 3
"""


def _get_winget_packages():
  """
  Run winget list for both user and machine scope, return dict keyed by
  'user-<username>' and 'machine', each a list of package ids.
  """
  if os.name != "nt":
    return {}

  try:
    out = subprocess.check_output(
      ["powershell", "-NoProfile", "-NonInteractive", "-Command", _PS_SCRIPT],
      text=True,
      timeout=60,
      stderr=subprocess.DEVNULL,
    )
    data = json.loads(out)
    # single-scope-result collapses dict keys to bare strings if only one key —
    # ConvertTo-Json still emits an object, so this is just defensive
    if not isinstance(data, dict):
      return {}
    for key, val in data.items():
      if isinstance(val, str):
        data[key] = [val]
      elif val is None:
        data[key] = []
    return data
  except Exception as e:
    log.error(f"Error detecting winget packages: {e}")
    return {}


def winget_packages():
  """
  Grain function - returns winget package inventory per scope.

  Usage in states:
      {% set pkgs = salt['grains.get']('winget_packages', {}) %}
  """
  return {"winget_packages": _get_winget_packages()}
