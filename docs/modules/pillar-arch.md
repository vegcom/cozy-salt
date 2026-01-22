# Pillar: Arch Linux Configuration

Arch Linux-specific default pillar configuration with AUR and pacman settings.

## Location

- **Pillar**: `srv/pillar/arch/init.sls`
- **Included in**: `top.sls` for Arch-based systems (Arch, Manjaro, EndeavourOS, etc.)

## Configures

```yaml
user:
  name: arch # Default admin user

workstation_role: workstation-full # Includes extra groups

nvm:
  default_version: "lts/*"

host:
  capabilities:
    kvm: false

pacman:
  parallel_downloads: 5 # Concurrent downloads
  color: true # Colored output
  checksums: sha256 # Checksum verification

aur:
  builder_user: builder # Non-root AUR builder
  build_dir: /tmp/makepkg # AUR build directory
```

## Default Role

Arch defaults to `workstation-full`:

- Includes: interpreters, fonts, theming, modern_cli_extras
- Additional capabilities unavailable on other distros

## Arch-Specific Packages

Unique to Arch (via yay):

- `github-cli` (not `gh`)
- `fd` (not `fd-find`)
- `base-devel` group (not individual packages)
- Arch-exclusive tools: eza, bottom, delta, hyperfine, procs, tealdeer, tokei

## Pacman Configuration

```yaml
pacman:
  parallel_downloads: 5 # Speed up downloads
  color: true # Colorized output
  checksums: sha256 # Verify integrity
```

## AUR Builder

Non-root AUR builder setup:

```yaml
aur:
  builder_user: builder # Unprivileged AUR builder
  build_dir: /tmp/makepkg
```

Requires sudoers configuration for pacman access.

## Customization

Override per-host:

```yaml
workstation_role: workstation-developer # Fewer packages
pacman:
  parallel_downloads: 10 # Faster downloads
```

## Notes

- Applied to Arch, Manjaro, EndeavourOS, Artix, Garuda, ArcoLinux
- Default role more generous (full set of extras)
- AUR builder non-root for security
- Parallel downloads speed up large updates
- Color output improves readability
