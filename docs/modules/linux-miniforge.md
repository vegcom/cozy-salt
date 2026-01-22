# Miniforge (Conda) - Linux

System-wide Miniforge installation to `/opt/miniforge3` for package/environment management.

## Location

- **State**: `srv/salt/linux/miniforge.sls`
- **Include**: `linux.init`
- **Package management**: `common.miniforge`

## Installation

Installs Miniforge from official releases: https://github.com/conda-forge/miniforge

| Item | Location |
|------|----------|
| Conda binary | `/opt/miniforge3/bin` |
| Shell init | `/etc/profile.d/miniforge-init.sh` |
| Environments | `~/.conda/envs/` |

## Pillar Configuration

```yaml
miniforge:
  version: latest  # or specific version
```

## Usage

```bash
conda --version        # Verify installation
conda create -n myenv  # Create environment
conda activate myenv   # Activate environment
conda install package  # Install packages
```

## Notes

- Requires curl (installed via core_utils)
- Shell profile auto-sources conda on login
- System-wide installation for all users
- ACL permissions: admin user can write to /opt/miniforge3
- Different from Windows miniforge (separate state)
