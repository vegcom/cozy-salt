#!/opt/miniforge3/python

import os
import sys
from pathlib import Path


def get_conda_env_name():
    """Reads the environment.yml file directly to find the environment name."""
    yml_path = Path("environment.yml")
    if not yml_path.exists():
        return None
    try:
        with open(yml_path, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("name:"):
                    return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return None


def find_conda_python_binary(env_name):
    """Locates the target python executable inside the active environment path cross-platform."""  # noqa: E501
    if not env_name:
        return sys.executable

    base_paths = [
        Path("/opt/miniforge3/envs") / env_name,
        Path(os.environ.get("USERPROFILE", "")) / "miniforge3" / "envs" / env_name,
        Path(os.environ.get("HOME", "")) / "miniforge3" / "envs" / env_name,
        Path(os.environ.get("CONDA_PREFIX", "")).parent / env_name
        if os.environ.get("CONDA_PREFIX")
        else Path("."),
    ]

    for base in base_paths:
        executable = base / "bin" / "python" if os.name != "nt" else base / "python.exe"
        if executable.exists():
            return str(executable)

    return sys.executable
