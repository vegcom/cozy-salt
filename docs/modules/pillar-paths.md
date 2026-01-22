# Pillar: Tool Installation Paths

Centralized tool installation paths with platform-specific defaults.

## Location

- **Pillar**: `srv/pillar/common/paths.sls`
- **Included in**: `top.sls` for all systems

## Configures

Paths for tools installed to non-standard locations:

```yaml
paths:
  nvm: /opt/nvm
  rust: /opt/rust
  miniforge: /opt/miniforge3
  homebrew: /opt/homebrew
  cozy: /opt/cozy
```

## Platform Defaults

| Tool      | Linux           | Windows           |
| --------- | --------------- | ----------------- |
| nvm       | /opt/nvm        | C:\opt\nvm        |
| rust      | /opt/rust       | C:\opt\rust       |
| miniforge | /opt/miniforge3 | C:\opt\miniforge3 |
| homebrew  | /opt/homebrew   | N/A               |
| cozy      | /opt/cozy       | C:\opt\cozy       |

## Usage in States

States reference paths via pillar:

```sls
nvm_install:
  cmd.run:
    - name: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash -s -- --prefix {{ salt['pillar.get']('paths:nvm') }}
```

## Customization

Override in pillar data:

```yaml
paths:
  nvm: /usr/local/nvm # Custom location
```

## Notes

- Standard locations prevent conflicts
- Platform-specific (no hardcoding)
- Shell profiles auto-source from these paths
- ACL permissions grant user write access
