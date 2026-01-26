# cozy-salt TODO

| thanks to | eve | veg | 3rd | 4th | 5th |
| --------- | --- | --- | --- | --- | --- |
| design    | ✅  | ✅  | 🔴  | 🔴  | 🔴  |
| delivery  | ✅  | ✅  | 🔴  | 🔴  | 🔴  |
| audit     | ✅  | 🔴  | 🔴  | 🔴  | 🔴  |

## URGENT

### Windows bootstrap - delivery

- fixes WinRM (cmd.run block)
- starts salt-minion

**Script state** - "get me to the point where Salt can talk to you."

**Bootstrap state** - "Make you behave like a predictable Windows target."

**Normal states** - "Make you you (hostname, roles, apps, cozy stuff)."

### Windows bootstrap - cmd

- enforce w **cmd.run**

- **provide for new provisions** via script, **enforce** once salted

```cmd
# Disable CredSSP requirement
winrm set winrm/config/client/auth @{CredSSP="false"}
winrm set winrm/config/service/auth @{CredSSP="false"}

# Allow unencrypted
winrm set winrm/config/service @{AllowUnencrypted="true"}
winrm set winrm/config/client @{AllowUnencrypted="true"}
```

### Windows regedit

- enforce with `reg.present`
- **provide for new provisions** via script, **enforce** once salted

```sls
# Disable “Admin Approval Mode” for the built‑in Administrator
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
  FilterAdministratorToken = 0 (DWORD)

# Make PowerShell execution deterministic
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force

# Disable consumer junk
HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent
  DisableConsumerFeatures = 1 (DWORD)

HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
  EnableFirstLogonAnimation = 0 (DWORD)

HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent
  DisableSoftLanding = 1 (DWORD)

# Disable reboot‑blocking auto‑updates
HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
  NoAutoRebootWithLoggedOnUsers = 1 (DWORD)
  AUOptions = 2 (DWORD) ; notify only

# Disable Delivery Optimization
HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization
  DODownloadMode = 0 (DWORD)

# Disable environment virtualization
HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System
  EnableVirtualization = 0 (DWORD)

# Force environment broadcast after changes
## Salt does not automatically broadcast WM_SETTINGCHANGE, so Windows services won’t see updated PATH
broadcast_env_change:
  cmd.run:
    - name: 'powershell -NoLogo -NoProfile -Command "[Environment]::SetEnvironmentVariable(\"PATH\", $env:PATH, \"Machine\")"'
    - onchanges:
      - reg: set_path

# Make sure SYSTEM sees the same PATH as users
## Since Salt runs as SYSTEM, you want SYSTEM’s environment to match HKLM exactly
sync_system_env:
  cmd.run:
    - name: 'powershell -NoLogo -NoProfile -Command "Set-Item -Path Env:PATH -Value (Get-ItemProperty -Path \"HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" -Name PATH).PATH"'
    - onchanges:
      - reg: set_path

# disable PATH poisoning
## Windows sometimes prepends random entries (OneDrive, OEM tools, etc.)
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer
  DisallowWin32kSystemCallFilter = 1

## disable “auto‑repair” of PATH
HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
  PathUnexpanded = 1
```

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

- [ ] Windows UAC management via GPO or registry [see](#urgent)
  - Disable UAC for managed systems to allow silent elevation (Start-Process -Verb RunAs)
  - Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA = 0`
  - Or GPO deployment for domain-joined systems
- [ ] Common ACL state for group management
  - Macro created: `srv/salt/macros/acl.sls` with `cozy_acl()`
  - Currently inline in nvm.sls, miniforge.sls, rust.sls
  - TODO: Centralize cozyusers group creation (currently ad-hoc)
  - TODO: Consider `srv/salt/common/acl.sls` for group membership management
  - TODO: Windows equivalent using `icacls` or PowerShell ACL cmdlets

- [ ] Pillar load order audit
  - Validate all pillar files are included in top.sls (mgmt.sls was missing)
  - Check for duplicate/conflicting keys across pillar files
  - Reduce redundant comments in pillar files
  - Document pillar merge behavior and precedence
  - Verify per-user pillar files (users/*.sls) merge correctly with common/users.sls
  - Fix password/passwords key mismatch (pillar uses `passwords`, states expect `password`)

- [ ] Provisioning directory cleanup
  - `provisioning/linux/files/steamdeck/` - weird path, doesn't follow `target-path` convention
  - `provisioning/linux/files/sddm/` - should be `etc-sddm.conf.d/` or similar
  - States reference both `/etc/sddm.conf` and `/etc/sddm.conf.d` - consolidate
  - All paths should mirror target with `-` replacing `/` (e.g., `etc-skel`, `opt-cozy`)

- [ ] Debug atuin integration (check: installed? PATH? .bashrc init? bash-preexec?)
- [ ] Move tests/ to cozy-salt-enrollment submodule (test_states.py, test_linting.py)
- [ ] Validate and enforce package_metadata (conflicts, exclude, provides resolution)

## Backlog

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
- [x] Integrate cozy-ssh (SSH config framework) - `srv/salt/linux/cozy-ssh.sls` clones to `/opt/cozy/cozy-ssh`, symlinks per-user

## Pending review

- [ ] Tailscale DNS nameserver append

## Small W(s)

## Merged upstraem

- [x] Salt bootstrap to leverage fork [vegcom/salt-bootstrap/develop/bootstrap-salt.sh](https://raw.githubusercontent.com/vegcom/salt-bootstrap/develop/bootstrap-salt.sh)
  - Pending approval [saltstack/salt-bootstrap/pull/2101](https://github.com/saltstack/salt-bootstrap/pull/2101)
  - install on linux as `salt-bootstrap.sh onedir latest`
  - `curl -fsSL https://raw.githubusercontent.com/vegcom/salt-bootstrap/refs/heads/develop/bootstrap-salt.sh | bash -s -- -D onedir latest`
