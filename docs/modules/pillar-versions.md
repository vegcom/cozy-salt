# Pillar: Tool Version Pinning

Centralized version pinning for tools and frameworks.

## Location

- **Pillar**: `srv/pillar/common/versions.sls`
- **Included in**: `top.sls` for all systems

## Configures

Version specifications for:

```yaml
versions:
  nvm_version: 'lts/*'         # Node version
  rust_toolchain: stable       # Rust version
  miniforge_version: latest    # Conda version
  windhawk_version: latest     # Windows customization tool
  wt_version: latest           # Windows Terminal version
  qmk_msys_version: latest     # QMK environment version
```

## Version Formats

| Tool | Format | Examples |
|------|--------|----------|
| NVM | SemVer or alias | 'lts/*', 'lts/gallium', 'v18.0.0' |
| Rust | Channel | stable, nightly, beta |
| Miniforge | Version or latest | latest, 23.1.0 |
| Windows tools | Version or latest | latest |

## Usage in States

States reference versions:

```sls
install_nvm:
  cmd.run:
    - name: nvm install {{ salt['pillar.get']('versions:nvm_version') }}
```

## Customization

Override for specific requirements:

```yaml
versions:
  nvm_version: 'v16.14.0'     # Lock to specific version
  rust_toolchain: nightly     # Use nightly Rust
  miniforge_version: '23.1.0'
```

## Update Cycle

- Regularly reviewed for security updates
- Breaking changes documented in releases
- Test in non-production first
- Commit version changes with testing results

## Notes

- Affects all users/systems
- Cross-platform consistency
- Major version changes may require testing
- Language-specific versions managed separately
