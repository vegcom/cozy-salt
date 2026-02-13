#!/usr/bin/env python3
"""
Repology MCP Server - Package name resolution across distros
Falls back to local map if API fails (wife's suggestion)
"""

import json
import sys
import httpx
from typing import Optional

# Local fallback map (mirrors packages.sls provides: section)
LOCAL_MAP = {
  "vim": {"ubuntu": "vim", "debian": "vim", "rhel": "vim-enhanced", "arch": "vim"},
  "fd": {"ubuntu": "fd-find", "debian": "fd-find", "rhel": "fd-find", "arch": "fd"},
  "ripgrep": {
    "ubuntu": "ripgrep",
    "debian": "ripgrep",
    "rhel": "ripgrep",
    "arch": "ripgrep",
  },
  "bat": {"ubuntu": "bat", "debian": "bat", "rhel": "bat", "arch": "bat"},
  "netcat": {
    "ubuntu": "netcat-openbsd",
    "debian": "netcat-openbsd",
    "rhel": "nmap-ncat",
    "arch": "openbsd-netcat",
  },
  "7zip": {"ubuntu": "7zip", "debian": "7zip", "rhel": "p7zip", "arch": "p7zip"},
  "ssh_client": {
    "ubuntu": "openssh-client",
    "debian": "openssh-client",
    "rhel": "openssh-clients",
    "arch": "openssh",
  },
  "ssh_server": {
    "ubuntu": "openssh-server",
    "debian": "openssh-server",
    "rhel": "openssh-server",
    "arch": "openssh",
  },
  "dns_utils": {
    "ubuntu": "bind9-dnsutils",
    "debian": "bind9-dnsutils",
    "rhel": "bind-utils",
    "arch": "bind",
  },
  "github_cli": {"ubuntu": "gh", "debian": "gh", "rhel": "gh", "arch": "github-cli"},
  "avahi": {
    "ubuntu": "avahi-daemon",
    "debian": "avahi-daemon",
    "rhel": "avahi",
    "arch": "avahi",
  },
  "build_essentials": {
    "ubuntu": "build-essential",
    "debian": "build-essential",
    "rhel": "gcc",
    "arch": "base-devel",
  },
}

# Repo name mapping for repology API
REPO_MAP = {
  "ubuntu": "ubuntu_24_04",
  "debian": "debian_12",
  "rhel": "fedora_41",  # repology uses fedora, close enough for RHEL
  "arch": "arch",
}

API_BASE = "https://repology.org/api/v1"
TIMEOUT = 5.0
USER_AGENT = "cozy-salt-mcp/0.1 (homelab saltstack; +https://github.com/)"


def query_repology(project: str) -> Optional[dict]:
  """Query repology API for package names across distros"""
  try:
    headers = {"User-Agent": USER_AGENT}
    resp = httpx.get(f"{API_BASE}/project/{project}", timeout=TIMEOUT, headers=headers)
    resp.raise_for_status()
    data = resp.json()

    result = {}
    for distro, repo_pattern in REPO_MAP.items():
      candidates = []
      for pkg in data:
        if not pkg.get("repo", "").startswith(repo_pattern.split("_")[0]):
          continue
        # Collect all possible names
        binname = pkg.get("binname")
        binnames = pkg.get("binnames") or []
        if binname:
          candidates.append(binname)
        candidates.extend(binnames)

      # Filter out junk (-doc, -debuginfo, etc)
      candidates = [
        c
        for c in candidates
        if c
        and not any(
          c.endswith(s)
          for s in ("-debuginfo", "-debugsource", "-doc", "-devel", "-dev")
        )
      ]

      if candidates:
        # Prefer: exact match > distro-specific suffix > contains project > shortest
        if project in candidates:
          result[distro] = project
        else:
          # RHEL prefers -enhanced suffix (e.g. vim-enhanced)
          if distro == "rhel":
            enhanced = [c for c in candidates if c.endswith("-enhanced")]
            if enhanced:
              result[distro] = enhanced[0]
              continue
          # Prefer names containing project name
          matching = [c for c in candidates if project in c]
          if matching:
            result[distro] = min(matching, key=len)
          else:
            result[distro] = min(candidates, key=len)

    return result if result else None
  except Exception as e:
    print(f"[repology] API error: {e}", file=sys.stderr)
    return None


def resolve_package(project: str) -> dict:
  """Resolve package name - API first, fallback to local map"""
  # Try API first
  api_result = query_repology(project)
  if api_result:
    return {"source": "repology", "mapping": api_result}

  # Fallback to local map
  if project in LOCAL_MAP:
    return {"source": "local", "mapping": LOCAL_MAP[project]}

  # Not found anywhere - return project name as-is for all distros
  return {"source": "passthrough", "mapping": {d: project for d in REPO_MAP.keys()}}


# MCP protocol handlers
def handle_tool_call(name: str, arguments: dict) -> dict:
  if name == "resolve_package":
    project = arguments.get("project", "")
    return resolve_package(project)
  elif name == "list_local_mappings":
    return {"mappings": list(LOCAL_MAP.keys())}
  elif name == "batch_resolve":
    projects = arguments.get("projects", [])
    return {p: resolve_package(p) for p in projects}
  else:
    return {"error": f"Unknown tool: {name}"}


def main():
  """MCP stdio server loop"""
  tools = [
    {
      "name": "resolve_package",
      "description": "Resolve canonical package name to distro-specific names",
      "inputSchema": {
        "type": "object",
        "properties": {
          "project": {
            "type": "string",
            "description": "Canonical package name (e.g. 'vim', 'fd', 'ripgrep')",
          }
        },
        "required": ["project"],
      },
    },
    {
      "name": "batch_resolve",
      "description": "Resolve multiple packages at once",
      "inputSchema": {
        "type": "object",
        "properties": {"projects": {"type": "array", "items": {"type": "string"}}},
        "required": ["projects"],
      },
    },
    {
      "name": "list_local_mappings",
      "description": "List all packages in local fallback map",
      "inputSchema": {"type": "object", "properties": {}},
    },
  ]

  # Simple MCP stdio protocol
  for line in sys.stdin:
    try:
      msg = json.loads(line)
      method = msg.get("method")
      msg_id = msg.get("id")

      if method == "initialize":
        response = {
          "jsonrpc": "2.0",
          "id": msg_id,
          "result": {
            "protocolVersion": "2024-11-05",
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "repology-mcp", "version": "0.1.0"},
          },
        }
      elif method == "tools/list":
        response = {"jsonrpc": "2.0", "id": msg_id, "result": {"tools": tools}}
      elif method == "tools/call":
        params = msg.get("params", {})
        result = handle_tool_call(params.get("name"), params.get("arguments", {}))
        response = {
          "jsonrpc": "2.0",
          "id": msg_id,
          "result": {
            "content": [{"type": "text", "text": json.dumps(result, indent=2)}]
          },
        }
      else:
        response = {"jsonrpc": "2.0", "id": msg_id, "result": {}}

      print(json.dumps(response), flush=True)
    except Exception as e:
      print(
        json.dumps(
          {"jsonrpc": "2.0", "id": None, "error": {"code": -1, "message": str(e)}}
        ),
        flush=True,
      )


if __name__ == "__main__":
  main()
