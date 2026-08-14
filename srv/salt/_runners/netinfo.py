"""
Salt runner — collects netinfo from a minion and writes /srv/data/network/{id}.json.

Called by reactor on salt/beacon/*/network_settings/* events.
"""

import datetime
import json
import logging
import os

log = logging.getLogger(__name__)

__virtualname__ = "netinfo"


def __virtual__():
    return __virtualname__


def collect(minion_id, data_dir="/srv/data/network"):
    """
    Collect wan_ips + default_gw from minion, write timestamped JSON to data_dir.

    CLI example::

        salt-run netinfo.collect guava
    """
    import salt.client

    client = salt.client.LocalClient()

    gw = client.cmd(minion_id, "netinfo.default_gw", timeout=15)
    wan = client.cmd(minion_id, "netinfo.wan_ips", timeout=15)

    gw_data = gw.get(minion_id) or {}
    wan_data = wan.get(minion_id) or []

    result = {
        "gateway": gw_data.get("gateway"),
        "interface": gw_data.get("interface"),
        "wan": wan_data,
        "__changed__": datetime.datetime.utcnow().isoformat() + "Z",
    }

    os.makedirs(data_dir, exist_ok=True)
    path = os.path.join(data_dir, f"{minion_id}.json")

    existing = {}
    if os.path.exists(path):
        try:
            with open(path) as f:
                existing = json.load(f)
        except Exception:
            pass

    changed = (
        existing.get("gateway") != result["gateway"]
        or existing.get("interface") != result["interface"]
        or existing.get("wan") != result["wan"]
    )

    if changed:
        with open(path, "w") as f:
            json.dump(result, f, indent=2)
        log.info("netinfo.collect: %s network changed, wrote %s", minion_id, path)
    else:
        log.debug("netinfo.collect: %s no change, skipping write", minion_id)

    return {"changed": changed, **result}
