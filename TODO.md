# cozy-salt TODO

## High priority

- [x] Add [scheduler](https://docs.saltproject.io/salt/user-guide/en/latest/topics/scheduler.html) (2025-01-21)

## Active

- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Move tests/ to cozy-salt-enrollment submodule (test_states.py, test_linting.py)
- [x] Add `package_metadata` to packages.sls (distro_aliases, conflicts, provides) (2025-01-21: structure defined in provisioning/packages.sls)
- [ ] Validate and enforce package_metadata (conflicts, exclude, provides resolution)
- [ ] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/refs/heads/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`

## Backlog

- [ ] Auto-inject "Managed by Salt - DO NOT EDIT MANUALLY" headers
  - Enumerate all provisioning files referenced in state sources (salt:// paths)
  - Inject header on file deploy if not present
  - Pre-commit hook or salt state to automate
  - Prevents manual effort, ensures consistency
- [ ] Cull verbose inline comments from .sls files, move to proper docs
- [x] Rewrite tests/test-states-json.sh in Python (pytest integration, better error handling) (2025-01-21: test_states.py + test_linting.py complete, culled shell test runners)
- [x] Windows: parameterize hardcoded paths via pillar (PowerShell, sshd_config.d) (2025-01-21: commit b460453)
- [x] Windows: pillar-driven scheduled tasks (2025-01-21: commit b67acd9)
- [x] SDDM astronaut theme (pillar gate: `steamdeck:sddm:theme`) (2025-01-21)

## Future

- [ ] IPA provisioning (awaiting secrets management solution - explore lightweight alternatives to Vault)
- [ ] Integrate cozy-fragments (Windows Terminal config fragments) - manual for now

## Pending review

- [ ] Tailscale DNS nameserver append
