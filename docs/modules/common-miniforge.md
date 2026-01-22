# Miniforge Package Management

Miniforge environment and permission management (cross-platform orchestration).

## Location

- **State**: `srv/salt/common/miniforge.sls`
- **Include**: `common.init`

## Purpose

Orchestrates miniforge installation across Linux/Windows with permissions and group setup.

## Operations

| Item | Purpose |
|------|---------|
| Permissions | Admin user write access to `/opt/miniforge3` (Linux) |
| Group ACL | Add admin user to conda group |
| Shell init | Ensure conda shell integration works |
| Environments | Initialize default environment |

## Pillar Configuration

```yaml
miniforge:
  version: latest
  channel_config:
    auto_activate_base: false
```

## Linux-Specific

- ACL: Admin user added to group for write access
- Path: `/opt/miniforge3/`
- Ownership: root, writable by group

## Windows-Specific

- Path: `C:\opt\miniforge3\`
- Registry: Sets up Windows-specific conda config
- Python: Installs as default Python interpreter

## Usage

```bash
conda --version        # Check installation
conda create -n myenv  # Create environment
conda activate myenv   # Activate
```

## Notes

- Requires miniforge to be installed first (via linux/windows install states)
- Cross-platform: same state file for Linux and Windows
- Respects existing conda configurations
