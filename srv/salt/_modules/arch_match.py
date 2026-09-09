"""
Generic arch-matching execution module.
Picks the best candidate (string or dict) from a list based on ordered regex
patterns. No knowledge of GitHub or any specific source — just pattern
matching against candidate names/urls. See docs/modules/arch_match.md.
"""

import logging
import re

log = logging.getLogger(__name__)

__virtualname__ = "arch_match"


def __virtual__():
    return __virtualname__


def pick(candidates, patterns, key=None, fallback=None):
    """
    Return the first candidate matching the first pattern (in order) that
    hits any candidate. Patterns are tried in priority order; within a
    pattern, candidates are tried in list order.

    :param candidates: list of str, or list of dict
    :param patterns: ordered list of regex strings (case-insensitive)
    :param key: if candidates are dicts, the key to extract the match string from
    :param fallback: returned if no pattern matches any candidate
    :returns: the matching candidate (original str or dict), or fallback

    CLI Example::

        salt '*' arch_match.pick '["nvm-1.2.2-amd64-setup.exe", "nvm-1.2.2-arm64-setup.exe"]' '["arm64", "aarch64"]'
    """
    if not candidates or not patterns:
        return fallback

    for pattern in patterns:
        try:
            rx = re.compile(pattern, re.IGNORECASE)
        except re.error as exc:  # noqa: BLE001
            log.warning("arch_match.pick: bad pattern %r: %s", pattern, exc)
            continue
        for candidate in candidates:
            target = candidate.get(key, "") if (key and isinstance(candidate, dict)) else candidate
            if isinstance(target, str) and rx.search(target):
                return candidate
    return fallback


def patterns_for(arch=None, os_family=None):
    """
    Look up arch_patterns:<os_family>:<arch> from pillar. Defaults to the
    current minion's osarch/os_family grains if not given.

    Expected pillar shape::

        arch_patterns:
          windows:
            amd64: ['x64', 'amd64', 'win64']
            arm64: ['arm64', 'aarch64']
          linux:
            amd64: ['amd64', 'x86_64', 'linux64']
            arm64: ['arm64', 'aarch64']

    CLI Example::

        salt '*' arch_match.patterns_for
        salt '*' arch_match.patterns_for arch=arm64 os_family=windows
    """
    _ARCH_ALIASES = {
        "x86_64": "amd64",
        "amd64": "amd64",
        "aarch64": "arm64",
        "arm64": "arm64",
    }

    arch = arch or __salt__["grains.get"]("osarch") or __salt__["grains.get"]("cpuarch")  # noqa: F821
    os_family = (os_family or __salt__["grains.get"]("os_family", "")).lower()  # noqa: F821
    family_key = "windows" if os_family == "windows" else "linux"
    arch_key = _ARCH_ALIASES.get((arch or "").lower(), (arch or "").lower())

    return __salt__["pillar.get"](f"arch_patterns:{family_key}:{arch_key}", [])  # noqa: F821


