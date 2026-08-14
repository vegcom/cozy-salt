# GPU vendor detection grain
# Detects: nvidia, amd, intel, other
# Usage: grains['gpu_vendor']
# TODO: test intel detection — look for "Intel Corporation" + "VGA\|3D\|Display"

import subprocess


def gpu_vendor():
    """Detect GPU vendor from lspci output."""
    try:
        lspci = subprocess.check_output(
            ["lspci"], text=True, stderr=subprocess.DEVNULL
        ).upper()
        if "NVIDIA" in lspci:
            return {"gpu_vendor": "nvidia"}
        elif any(x in lspci for x in ["AMD", "RADEON", "AMDGPU"]):
            return {"gpu_vendor": "amd"}
        elif "INTEL" in lspci and any(x in lspci for x in ["VGA", "3D", "DISPLAY"]):
            return {"gpu_vendor": "intel"}
    except Exception:
        pass
    return {"gpu_vendor": "other"}
