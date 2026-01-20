# cozy-salt TODO

## Active
- [ ] Expand `provisioning/packages.sls` arch section: interpreters, atuin, modern_cli_extras
- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Add `package_metadata` to packages.sls (distro_aliases, conflicts, provides)

## Backlog

- [ ] Rewrite tests/test-states-json.sh in Python (pytest integration, better error handling)
- [ ] Windows: parameterize hardcoded paths via pillar (PowerShell, sshd_config.d)
- [ ] Windows: pillar-driven scheduled tasks
- [ ] SDDM astronaut theme (pillar gate: `steamdeck:sddm:theme`)
- [ ] Immutable Linux support (Flatpak/distrobox for read-only filesystems)
- [ ] Tailscale DNS nameserver append
