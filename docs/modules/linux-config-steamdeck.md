# Steam Deck Configuration

Hardware-specific configuration for Valve Steam Deck (Galileo).

## Location

- **State**: `srv/salt/linux/config-steamdeck.sls`
- **Include**: `linux.init`
- **Target**: Detected via grains: biosvendor=Valve AND boardname=Galileo

## Configures

| Item | Purpose |
|------|---------|
| SDDM | Display manager and theme (astronaut theme) |
| Display | Framebuffer and graphics settings |
| Input | Gamepad/controller mappings |
| Performance | CPU frequency scaling, thermal settings |

## Configuration Files

Deployed from `provisioning/linux/files/steamdeck/`:
- SDDM theme configuration
- Display settings for handheld res (1280x800)
- Input device configuration
- Systemd units for performance tuning

## Pillar Configuration

```yaml
steamdeck:
  sddm:
    theme: astronaut  # or other available theme
  cpu_governor: ondemand
  performance_profile: balanced
```

## Auto-Detection

Only runs on hardware matching:
- Vendor: Valve
- Board: Galileo
- Grains: `biosvendor` and `boardname`

## Notes

- No-op on non-Steam Deck systems
- Changes are persistent across reboots
- Respects user customizations (not overwrite-forced)
- Some settings may require SteamOS module updates
