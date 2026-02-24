# cozy-salt TODO

## Pending testing

```powershell
# Developer mode
reg add "hklm\software\microsoft\windows\currentversion\appmodelunlock" /v "AllowDevelopmentWithoutDevLicense" /t reg_dword /d 1 /f

DISM /Online /Add-Capability /CapabilityName:Tools.DeveloperMode.Core~~~~0.0.1.0

# WSL
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all
```

## pending deployment

### URGENT

#### Upmost urgency

- [x] fix pillar merge order and priority (refactor/pillar-load-order branch)
  - common → os → dist → class → users → host
    - host is LAST = final word on machine-specific overrides
    - each layer can append to or overwrite previous
  - [x] top.sls refactored with clear layer comments
  - [x] fixed host_file path check (/srv/pillar/ not /srv/salt/pillar/)
  - [x] users/*.sls now loaded (Layer 5)
  - [ ] all values audited
  - [ ] all values used where expected
  - [ ] no unexpected values remain
- templates in provisioning/{windws,linux}/templates
  - see below regarding all complex logic ( where possible ) deferred to templates
- all complex sls files doing file.managed with content are deferred to templates
  - all macros are in srv/salt/\_macros
  - all complex logic is reduced to macro or templates

<https://gist.github.com/Rishikant181/e26fb23d4c57db74bddaa0a57b26cd26#5-creating-a-script-to-switch-back-to-desktop-mode-close-steam>

## Modern changes

### High

- [ ] replace old admin references for install and defer to service user where possible, som examples below
  - `{% set service_user = salt['pillar.get']('managed_users', ['admin'])[0] %}`
  - `runas: admin`

## Seperation of duty

- [ ] Refactor config.sls
  - Presently config.sls is doing a lot of heavy lifting
  - Can be seperated by module/state

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

### Windows highstate fixes (2025-02)

- [x] Choco feature states return exit code 2 for "already set" (564b8c1)
- [x] Winget userland installs fail for users without profiles (733a86b)
- [x] Git safe.directory not set for SYSTEM user (542d64a)
- [x] PowerShell execution policy fails on fresh install (883d72a)
- [x] Profile health check regex syntax error
  - Missing closing quote in `-match '\.\w+-\w+` pattern

### ProfileList user detection

- [x] Audit Windows installers for ProfileList-based user detection
  - winget, miniforge, rust, nvm on Windows
  - Use `get_winget_user()` macro pattern (ProfileList registry check)
  - Service accounts can't run AppX/MSIX - need real interactive user
- [x] Windows UAC management via GPO or registry [see](#urgent)
  - Disable UAC for managed systems to allow silent elevation (Start-Process -Verb RunAs)
  - Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA = 0`
  - Or GPO deployment for domain-joined systems
- [~] Pillar load order audit (in progress: refactor/pillar-load-order)
  - [x] Validate all pillar files are included in top.sls (mgmt.sls was missing)
  - [x] Check for duplicate/conflicting keys across pillar files
    - Added `pacman:repos_extra` pattern for append behavior
  - [x] Reduce redundant comments in pillar files (refactor/pillar-load-order)
  - [x] Document pillar merge behavior and precedence (in top.sls comments)
  - [x] Verify per-user pillar files (users/*.sls) merge correctly with common/users.sls
  - [x] Fix password/passwords key mismatch (users/*.sls: passwords → password)

- [ ] Move tests/ to cozy-salt-enrollment submodule (test_states.py, test_linting.py)

## Linux / Infra

- [x] **k3s.sls**: evaluate multi-node cluster vs client-only mode before finalising state design
- [x] **k3s.sls**: replace `k3s_download_script` / `k3s_setup_script` `cmd.run` with `file.managed` + `cmd.run` pattern (binary from pillar-versioned URL + sha256 hash)
- [ ] **cmd.run audit**: grep all states for `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern (k3s pattern as reference)
- [x] **managed_users**: switch all `pillar.get('managed_users', [])` calls to `merge=True` so host pillars append instead of replace
- [ ] **masters list**: add `salt.masters` to `srv/pillar/common/salt.sls`, wire into `linux/salt_minion.sls` + `windows/salt_minion.sls`
- [ ] **salt_minion states**: create `common/salt_minion.sls`, `linux/salt_minion.sls`, `windows/salt_minion.sls` — manage minion config, source master from pillar

## Backlog

- [ ] Extract distro_aliases + package_metadata.provides to separate .map file
  - `provisioning/distro.map` or `provisioning/packages.map`
  - Use `import_yaml` to load, cleaner separation from pkg lists
  - Salt osmap pattern: <https://docs.saltproject.io/salt/user-guide/en/latest/topics/jinja.html>
- [ ] Auto-inject "Managed by Salt - DO NOT EDIT MANUALLY" headers
  - Enumerate all provisioning files referenced in state sources (salt:// paths)
  - Inject header on file deploy if not present
  - Pre-commit hook or salt state to automate
  - Prevents manual effort, ensures consistency
- [ ] Cull verbose inline comments from .sls files, move to proper docs

## Future

- [ ] IPA provisioning (awaiting secrets management solution - explore lightweight alternatives to Vault)
- [ ] BM provisioning (awaiting foreman replacement - explore lightweight alternatives for x86_64 && arm)
- [ ] Integrate cozy-fragments (Windows Terminal config fragments) - manual for now <<<git@github.com>:vegcom/cozy-fragments.git>>
- [x] Integrate cozy-ssh (SSH config framework) - `srv/salt/linux/cozy-ssh.sls` clones to `/opt/cozy/cozy-ssh`, symlinks per-user - <https://github.com/vegcom/cozy-ssh>

## Pending review

- [ ] Tailscale DNS nameserver append

## Small W(s)

## Merged upstraem

- [x] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`
