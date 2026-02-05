# cozy-salt TODO

| thanks to | eve | veg | 3rd | 4th | 5th |
| --------- | --- | --- | --- | --- | --- |
| design    | ✅  | ✅  | 🔴  | 🔴  | 🔴  |
| delivery  | ✅  | ✅  | 🔴  | 🔴  | 🔴  |
| audit     | ✅  | 🔴  | 🔴  | 🔴  | 🔴  |

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

### CCache for arch

- <https://man.archlinux.org/man/makepkg.conf.5>
- <https://wiki.archlinux.org/title/Ccache>

#### Windows bootstrap - delivery

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

### Windows highstate fixes (2025-02)

- [x] Choco feature states return exit code 2 for "already set" (564b8c1)
- [x] Winget userland installs fail for users without profiles (733a86b)
- [x] Git safe.directory not set for SYSTEM user (542d64a)
- [x] PowerShell execution policy fails on fresh install (883d72a)
- [ ] Profile health check regex syntax error
  - Missing closing quote in `-match '\.\w+-\w+` pattern

### ProfileList user detection

- [ ] Audit Windows installers for ProfileList-based user detection
  - winget, miniforge, rust, nvm on Windows
  - Use `get_winget_user()` macro pattern (ProfileList registry check)
  - Service accounts can't run AppX/MSIX - need real interactive user
- [ ] Windows UAC management via GPO or registry [see](#urgent)
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

## Backlog

- [ ] Extract distro_aliases + package_metadata.provides to separate .map file
  - `provisioning/distro.map` or `provisioning/packages.map`
  - Use `import_yaml` to load, cleaner separation from pkg lists
  - Salt osmap pattern: https://docs.saltproject.io/salt/user-guide/en/latest/topics/jinja.html
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
