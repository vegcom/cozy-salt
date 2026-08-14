"""
GitHub Release execution module.
Queries the GitHub API for latest release tag.
See docs/modules/github_release.md for usage.
"""

import json
import logging
import urllib.error
import urllib.request

log = logging.getLogger(__name__)

__virtualname__ = "github_release"

_token_cache = None


def __virtual__():
    return __virtualname__


def _collect_tokens():
    """Gather all github tokens from pillar — global + per-user."""
    tokens = []
    try:
        tokens.extend(__salt__["pillar.get"]("github:tokens", []))  # noqa: F821
        users = __salt__["pillar.get"]("users", {})  # noqa: F821
        for _username, userdata in users.items():
            tokens.extend(userdata.get("github", {}).get("tokens", []))
    except Exception:  # noqa: BLE001
        pass
    return tokens


def find_valid_token():
    """
    Return the first github token that passes a basic auth check. Result is
    cached per run.

    Reads tokens from all per-user pillar files via slsutil.renderer.


    CLI Example::

        salt '*' github_release.find_valid_token
    """
    global _token_cache
    if _token_cache is not None:
        return _token_cache

    candidates = _collect_tokens()

    for candidate in candidates:
        req = urllib.request.Request("https://api.github.com/user")
        req.add_header("Authorization", f"Bearer {candidate}")
        req.add_header("Accept", "application/vnd.github+json")
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                if resp.status == 200:
                    _token_cache = candidate
                    return _token_cache
        except Exception:  # noqa: BLE001
            continue
    _token_cache = ""
    return _token_cache


def latest(repo, fallback=None, prerelease=False):
    """
    Get the latest release tag for a GitHub repo.

    :param repo: GitHub repo in owner/name format (e.g. 'Nonary/vibeshine')
    :param fallback: Value to return if the API call fails
    :param prerelease: If True, include pre-release builds (default: False)
    :returns: Version string (tag_name without leading 'v'), or fallback

    CLI Example::

        salt '*' github_release.latest Nonary/vibeshine
        salt '*' github_release.latest microsoft/winget-cli prerelease=True
    """
    token = find_valid_token()
    if prerelease:
        url = f"https://api.github.com/repos/{repo}/releases"
    else:
        url = f"https://api.github.com/repos/{repo}/releases/latest"
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github+json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")

    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            if prerelease:
                return data[0]["tag_name"]
            return data["tag_name"]
    except Exception as exc:  # noqa: BLE001
        log.warning("github_release.latest(%s) failed: %s", repo, exc)
        return fallback
