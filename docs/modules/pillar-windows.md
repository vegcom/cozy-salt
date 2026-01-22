# Pillar: Windows Configuration

Windows-specific default pillar configuration.

## Location

- **Pillar**: `srv/pillar/windows/init.sls`
- **Included in**: `top.sls` for all Windows systems

## Configures

```yaml
user:
  name: Administrator # Default admin user

nvm:
  default_version: "lts"

rust:
  toolchain: stable

miniforge:
  version: latest
```

## User Detection

Auto-detects admin user:

```yaml
user:
  name: { { detected_user } }
```

Detection order:

1. %USERNAME% environment variable
2. Falls back to: `Administrator`

## NVM Configuration

Windows uses nvm-windows (different from Linux):

```yaml
nvm:
  default_version: "lts" # or 'lts/gallium', '18.0.0'
```

## Rust Configuration

Rust toolchain selection:

```yaml
rust:
  toolchain: stable # or nightly, beta
```

## Miniforge Configuration

Conda environment setup:

```yaml
miniforge:
  version: latest
  channel_config:
    auto_activate_base: false
```

## Customization

Override in host-specific pillar:

```yaml
user:
  name: custom_user # Custom admin user
nvm:
  default_version: v16 # Specific Node version
```

## Notes

- Applied to all Windows systems
- User auto-detected from environment
- nvm-windows specific (separate from Linux nvm)
- Registry-based configuration
- PATH managed via registry
