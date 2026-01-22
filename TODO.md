# cozy-salt TODO

## High priority

- [x] Add [scheduler](https://docs.saltproject.io/salt/user-guide/en/latest/topics/scheduler.html) (2025-01-21)

## Active

- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Add `package_metadata` to packages.sls (distro_aliases, conflicts, provides)
- [ ] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/refs/heads/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`

## Backlog

- [ ] Cull verbose inline comments from .sls files, move to proper docs
- [x] Rewrite tests/test-states-json.sh in Python (pytest integration, better error handling) (2025-01-21: test_states.py + test_linting.py complete, culled shell test runners)
- [x] Windows: parameterize hardcoded paths via pillar (PowerShell, sshd_config.d) (2025-01-21: commit b460453)
- [x] Windows: pillar-driven scheduled tasks (2025-01-21: commit b67acd9)
- [x] SDDM astronaut theme (pillar gate: `steamdeck:sddm:theme`) (2025-01-21)

## Pending review

- [ ] Tailscale DNS nameserver append
