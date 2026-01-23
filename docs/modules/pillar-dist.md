# Pillar: Distribution-Specific Configuration

Distribution-specific pillar defaults in `srv/pillar/dist/`.

## Files

| File | Distros | Key Config |
|------|---------|------------|
| [arch.sls](../../srv/pillar/dist/arch.sls) | Arch, Manjaro, EndeavourOS | pacman repos, AUR, workstation_role |

## Adding a Distro

1. Create `srv/pillar/dist/{distro}.sls`
2. Add to `srv/pillar/top.sls` with compound match
3. Update this table

## Common Keys

```yaml
workstation_role: workstation-base  # Package selection tier
user:
  name: detected                    # Default user
capability_meta:                    # How capabilities install
  core_utils:
    state_name: core_utils_packages
```

## Arch-Specific

- `pacman.repos` - Repository configuration
- `aur_user` - Non-root AUR builder
- `capability_meta` - Arch package state mappings
