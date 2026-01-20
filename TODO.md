# cozy-salt TODO

## High priority

- [ ] Add [scheduler](https://docs.saltproject.io/salt/user-guide/en/latest/topics/scheduler.html)

## Active

- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Add `package_metadata` to packages.sls (distro_aliases, conflicts, provides)
- [ ] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/refs/heads/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`
  - [x] Break out enrollment scripts into submodule
    - [ ] add submodule helpers to `Makefile`
      - [ ]`git submodule update --init --recursive`
      - [ ]`git submodule update --recursive --remote`

## Backlog

- [ ] Cull verbose inline comments from .sls files, move to proper docs
- [ ] Rewrite tests/test-states-json.sh in Python (pytest integration, better error handling)
- [ ] Windows: parameterize hardcoded paths via pillar (PowerShell, sshd_config.d)
- [ ] Windows: pillar-driven scheduled tasks
- [ ] SDDM astronaut theme (pillar gate: `steamdeck:sddm:theme`)
- [ ] Immutable Linux support (Flatpak/distrobox for read-only filesystems)
- [ ] Tailscale DNS nameserver append
