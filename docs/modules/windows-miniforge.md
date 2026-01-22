# Miniforge (Conda) - Windows

Miniforge installation to `C:\opt\miniforge3` for Python environment management.

## Location

- **State**: `srv/salt/windows/miniforge.sls`
- **Include**: `windows.init`
- **Package management**: `common.miniforge`

## Installation

Installs Miniforge from official releases:
<https://github.com/conda-forge/miniforge>

| Item         | Location                       |
| ------------ | ------------------------------ |
| Conda binary | `C:\opt\miniforge3`            |
| Python       | `C:\opt\miniforge3\python.exe` |
| Environments | `%USERPROFILE%\.conda\envs\`   |

## Pillar Configuration

```yaml
miniforge:
  version: latest
  channel_config:
    auto_activate_base: false
```

## Registry Configuration

Sets Windows registry entries for:

- Python association
- Conda default channels
- Base environment activation

## Usage

```cmd
conda --version        REM Check installation
conda create -n myenv  REM Create environment
conda activate myenv   REM Activate
conda install package  REM Install packages
```

## Notes

- Registry-based configuration (Windows-specific)
- PATH auto-configured by installer
- Affects all users
- Python is default interpreter for .py files
