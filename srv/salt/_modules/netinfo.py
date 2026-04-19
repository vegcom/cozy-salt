"""
Salt execution module for WAN and gateway discovery.

Pillar keys: none — uses grains and public ipify API.
"""

import logging

log = logging.getLogger(__name__)

__virtualname__ = "netinfo"


def __virtual__():
  return __virtualname__


def wan_ips():
  """
  Return public WAN IPs (v4 + v6, deduplicated).

  CLI example::

      salt 'guava' network.wan_ips
  """
  import salt.utils.http

  result = set()
  for url in (
    "https://api.ipify.org?format=json",
    "https://api64.ipify.org?format=json",
  ):
    r = salt.utils.http.query(url, decode=True, decode_type="json", verify_ssl=True)
    ip = r.get("dict", {}).get("ip")
    if ip:
      result.add(ip)
  return sorted(result)


def default_gw():
  """
  Return default gateway as {'gateway': '...', 'interface': '...'}.

  CLI example::

      salt 'guava' network.default_gw
  """
  os_family = __grains__.get("os_family", "")

  if os_family == "Windows":
    import json

    out = __salt__["cmd.run"](
      "Get-NetRoute -DestinationPrefix '0.0.0.0/0' | "
      "Select-Object -First 1 NextHop,InterfaceAlias | ConvertTo-Json",
      shell="powershell",
    )
    try:
      data = json.loads(out)
      return {"gateway": data.get("NextHop"), "interface": data.get("InterfaceAlias")}
    except Exception as exc:
      log.error("network.default_gw (windows) failed: %s", exc)
      return {}
  else:
    import json

    try:
      out = __salt__["cmd.run"]("ip -j route show")
      for route in json.loads(out):
        if route.get("dst") == "default":
          return {"gateway": route.get("gateway"), "interface": route.get("dev")}
    except Exception as exc:
      log.error("network.default_gw (linux) failed: %s", exc)
    return {}
