# Storage layout detection grains
# Detects whether /storage is on a separate block device from /
# Usage: grains['cozy_non_root_storage'] -> True/False
#        grains['cozy_storage_path']     -> '/storage' or None

import subprocess


def storage_layout():
    """Detect if /storage is on a separate device from /."""
    result = {"cozy_non_root_storage": False, "cozy_storage_path": None}
    try:

        def _get_dev(path):
            out = subprocess.check_output(
                ["findmnt", "-n", "-o", "SOURCE", "--target", path],
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
            return out or None

        root_dev = _get_dev("/")
        storage_dev = _get_dev("/storage")
        if root_dev and storage_dev and root_dev != storage_dev:
            result["cozy_non_root_storage"] = True
            result["cozy_storage_path"] = "/storage"
    except Exception:
        pass
    return result
