"""
GitHub Release execution module.
Queries the GitHub API for latest release tag.
See docs/modules/github_release.md for usage.
"""

import json
import urllib.error
import urllib.request

__virtualname__ = "github_release"


def __virtual__():
  return __virtualname__


def latest(repo, fallback=None):
  """
  Get the latest release tag for a GitHub repo.

  :param repo: GitHub repo in owner/name format (e.g. 'Nonary/vibeshine')
  :param fallback: Value to return if the API call fails
  :returns: Version string (tag_name without leading 'v'), or fallback

  CLI Example::

      salt '*' github_release.latest Nonary/vibeshine
  """
  token = __salt__["pillar.get"]("github:access_token", "")
  url = f"https://api.github.com/repos/{repo}/releases/latest"
  req = urllib.request.Request(url)
  req.add_header("Accept", "application/vnd.github+json")
  if token:
    req.add_header("Authorization", f"Bearer {token}")

  try:
    with urllib.request.urlopen(req, timeout=5) as resp:
      data = json.loads(resp.read())
      return data["tag_name"].lstrip("v")
  except Exception as exc:  # noqa: BLE001
    __salt__["log.warning"](f"github_release.latest({repo}) failed: {exc}")
    return fallback
