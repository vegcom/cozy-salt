"""
Salt execution module for querying the Headscale API.

Pillar keys (from srv/pillar/secrets/tailscale.sls):
  headscale:api-key       - API key for authentication
  headscale:login-server  - Base URL (e.g. https://headscale.example.com)
"""

import logging

log = logging.getLogger(__name__)

__virtualname__ = "headscale"


def __virtual__():
  return __virtualname__


def _api_key():
  return __pillar__.get("headscale", {}).get("api-key", "")


def _base_url():
  return __pillar__.get("headscale", {}).get("login-server", "").rstrip("/")


def _get(path):
  """Make a GET request to the headscale API."""
  import salt.utils.http

  base = _base_url()
  if not base:
    return {}
  url = base + path
  result = salt.utils.http.query(
    url,
    method="GET",
    header_dict={"Authorization": f"Bearer {_api_key()}"},
    decode=True,
    decode_type="json",
    verify_ssl=True,
  )
  if "error" in result:
    log.error("headscale API error for %s: %s", path, result["error"])
    return None
  return result.get("dict")


def get_nodes():
  """
  Return all nodes as a list of dicts.

  CLI example::

      salt 'guava' headscale.get_nodes
  """
  data = _get("/api/v1/node")
  if data is None:
    return []
  return data.get("nodes", [])


def get_node_ip(name, ipv6=False):
  """
  Return the tailscale IP for a node by name.

  name
      The node's givenName / hostname.
  ipv6
      If True, return the IPv6 address instead. Default False.

  CLI example::

      salt 'guava' headscale.get_node_ip papaya
  """
  idx = 1 if ipv6 else 0
  for node in get_nodes():
    if node.get("givenName") == name or node.get("name") == name:
      ips = node.get("ipAddresses", [])
      if len(ips) > idx:
        return ips[idx]
  return None


def get_online_nodes():
  """
  Return only currently online nodes.

  CLI example::

      salt 'guava' headscale.get_online_nodes
  """
  return [n for n in get_nodes() if n.get("online")]


def node_map(ipv6=False):
  """
  Return a dict mapping node name to tailscale IP.

  ipv6
      If True, return IPv6 addresses. Default False.

  CLI example::

      salt 'guava' headscale.node_map
  """
  idx = 1 if ipv6 else 0
  result = {}
  for node in get_nodes():
    name = node.get("givenName") or node.get("name")
    ips = node.get("ipAddresses", [])
    if name and len(ips) > idx:
      result[name] = ips[idx]
  return result


def get_nodes_by_tag(tag, online_only=True):
  """
  Return nodes with a specific tag.

  tag
      Tag to filter by (e.g. "tag:distcc_x86_64")
  online_only
      If True, only return online nodes. Default True.

  CLI example::

      salt 'guava' headscale.get_nodes_by_tag tag:distcc_x86_64
  """
  nodes = get_online_nodes() if online_only else get_nodes()
  # Tags may include "tag:" prefix or not
  tag_normalized = tag if tag.startswith("tag:") else f"tag:{tag}"
  return [n for n in nodes if tag_normalized in n.get("tags", [])]


def get_distcc_hosts(tag="distcc", online_only=True):
  """
  Return space-separated hostnames for DISTCC_HOSTS.

  tag
      Tag name without 'tag:' prefix (e.g. "distcc", "distcc-arm64"). Default "distcc".
  online_only
      If True, only return online nodes. Default True.

  CLI example::

      salt 'guava' headscale.get_distcc_hosts
      salt 'guava' headscale.get_distcc_hosts tag=distcc-arm64
  """
  nodes = get_nodes_by_tag(f"tag:{tag}", online_only=online_only)
  hostnames = [n.get("givenName") or n.get("name") for n in nodes]
  return " ".join(hostnames)
