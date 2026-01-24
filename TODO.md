# cozy-salt TODO

## Reactor

- [ ] Windows health-check reactor
  - Scheduler: `Dism /Online /Cleanup-Image /ScanHealth`
  - Reactor: on bad return (exit 1), fire `emergency-maint.ps1`
  - Scripts: `provisioning/windows/files/opt-cozy/emergency-maint.ps1`

- [ ] Auto inject headers w reactor
  - review auto-inject ( git, file )

```jinja
# auto_inject:
#   - name: header
#     context: file.managed
#     template: |
#       # source: {{ source }}
#       # Managed by Salt - DO NOT EDIT MANUALLY
```

## Active

- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Move tests/ to cozy-salt-enrollment submodule (test_states.py, test_linting.py)
- [ ] Validate and enforce package_metadata (conflicts, exclude, provides resolution)
- [ ] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/refs/heads/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`

## Backlog

- [ ] Windows UAC management via GPO or registry
  - Disable UAC for managed systems to allow silent elevation (Start-Process -Verb RunAs)
  - Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA = 0`
  - Or GPO deployment for domain-joined systems
- [ ] Auto-inject "Managed by Salt - DO NOT EDIT MANUALLY" headers
  - Enumerate all provisioning files referenced in state sources (salt:// paths)
  - Inject header on file deploy if not present
  - Pre-commit hook or salt state to automate
  - Prevents manual effort, ensures consistency
- [ ] Cull verbose inline comments from .sls files, move to proper docs

## Future

- [ ] IPA provisioning (awaiting secrets management solution - explore lightweight alternatives to Vault)
- [ ] Integrate cozy-fragments (Windows Terminal config fragments) - manual for now

## Pending review

- [ ] Tailscale DNS nameserver append
