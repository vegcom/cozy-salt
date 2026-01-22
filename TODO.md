# cozy-salt TODO

## Recent (2025-01-22)

- [x] Extract general Linux features from Steam Deck-specific state (commit f86174e)
  - SDDM, Bluetooth, autologin now in general states, pillar-gated
  - config-login-manager.sls, config-bluetooth.sls created
- [x] Fix GitHub PAT credential format in .git-credentials (commit dbed628)
  - Format: `https://[username]:[token]@github.com`
- [x] Create SDDM config files in provisioning/linux/files/sddm/ (commit d15b6c5)
- [x] Remove invalid git parameters from archlinux.sls yay bootstrap (commit d15b6c5)

## High priority

- [x] Add [scheduler](https://docs.saltproject.io/salt/user-guide/en/latest/topics/scheduler.html) (2025-01-21)

## Active

- [ ] Service account tooling (2025-01-22)
  - **Short-term**: Create `srv/salt/macros/service-account.sls` for lifecycle management (create → use → cleanup)
  - **Med-term**: Move existing macros to `srv/lib/macros/` (consolidate dotfiles.sls, gpu.sls, etc)
  - **Long-term**: Add `srv/lib/modules/` for custom Salt modules, update file_roots config
  - Pillar: `service_user` key in common for configurable service account name
  - Use for Windows admin user creation and system-level operations
- [ ] Admin user creation on Windows (2025-01-22)
  - Create `admin` user explicitly (currently excluded, uses built-in Administrator)
  - Integrate with service account tooling
  - Add to managed users group structure
- [ ] Evaluate provisioning users from pillar for winget (2025-01-22)
  - Option: Use service account or provision user list for system winget installs instead of SYSTEM
  - Research SYSTEM account winget blocker and workarounds
  - Update `srv/salt/windows/install.sls` accordingly
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
