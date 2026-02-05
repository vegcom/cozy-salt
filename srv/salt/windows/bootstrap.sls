# Windows Bootstrap State
# "Make you behave like a predictable Windows target"
# Run EARLY - before normal states, after script state gets Salt talking
# See TODO.md for full context

{% from '_macros/windows.sls' import get_winget_user, get_winget_path with context %}

# ============================================================================
# WinRM Configuration (Salt communication foundation)
# ============================================================================

# Enable WinRM service first - required before any winrm set commands
winrm_quickconfig:
  cmd.run:
    - name: winrm quickconfig -force
    - shell: cmd

winrm_disable_credssp_client:
  cmd.run:
    - name: winrm set winrm/config/client/auth @{CredSSP="false"}
    - shell: cmd
    - require:
      - cmd: winrm_quickconfig

winrm_disable_credssp_service:
  cmd.run:
    - name: winrm set winrm/config/service/auth @{CredSSP="false"}
    - shell: cmd
    - require:
      - cmd: winrm_quickconfig

winrm_allow_unencrypted_service:
  cmd.run:
    - name: winrm set winrm/config/service @{AllowUnencrypted="true"}
    - shell: cmd
    - require:
      - cmd: winrm_quickconfig

winrm_allow_unencrypted_client:
  cmd.run:
    - name: winrm set winrm/config/client @{AllowUnencrypted="true"}
    - shell: cmd
    - require:
      - cmd: winrm_quickconfig

# ============================================================================
# UAC / Elevation Settings
# ============================================================================

# Disable "Admin Approval Mode" for built-in Administrator
uac_filter_admin_token:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    - vname: FilterAdministratorToken
    - vdata: 0
    - vtype: REG_DWORD

# Disable environment virtualization (causes permission weirdness)
uac_disable_virtualization:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    - vname: EnableVirtualization
    - vdata: 0
    - vtype: REG_DWORD

# ============================================================================
# PowerShell Configuration
# ============================================================================

# Set execution policy via registry - more reliable than cmdlet on fresh installs
# (Set-ExecutionPolicy can fail if Microsoft.PowerShell.Security module isn't loaded)
powershell_execution_policy:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell
    - vname: ExecutionPolicy
    - vdata: Bypass
    - vtype: REG_SZ

# ============================================================================
# Disable Consumer Junk
# ============================================================================

disable_consumer_features:
  reg.present:
    - name: HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent
    - vname: DisableConsumerFeatures
    - vdata: 1
    - vtype: REG_DWORD

disable_first_logon_animation:
  reg.present:
    - name: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
    - vname: EnableFirstLogonAnimation
    - vdata: 0
    - vtype: REG_DWORD

disable_soft_landing:
  reg.present:
    - name: HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent
    - vname: DisableSoftLanding
    - vdata: 1
    - vtype: REG_DWORD

# ============================================================================
# Windows Update Settings (no surprise reboots)
# ============================================================================

wu_no_auto_reboot:
  reg.present:
    - name: HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
    - vname: NoAutoRebootWithLoggedOnUsers
    - vdata: 1
    - vtype: REG_DWORD

wu_notify_only:
  reg.present:
    - name: HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
    - vname: AUOptions
    - vdata: 2
    - vtype: REG_DWORD

# Disable Delivery Optimization (P2P update sharing)
disable_delivery_optimization:
  reg.present:
    - name: HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization
    - vname: DODownloadMode
    - vdata: 0
    - vtype: REG_DWORD


# ============================================================================
# Bootstrap Package Installation (using powershell 5.1, not pwsh)
# These MUST install before any state that uses shell: pwsh or git.latest
# Winget is per-user - detect user who has logged in
# ============================================================================

{% set winget_user = get_winget_user() %}
{% set winget_path = get_winget_path(winget_user) %}

winget_bootstrap:
  cmd.run:
    - name: >
        {{ winget_path }} source enable msstore --accept-source-agreements --disable-interactivity;
        {{ winget_path }} source update --disable-interactivity
    - shell: powershell
    - runas: {{ winget_user }}
    - onlyif: Test-Path '{{ winget_path }}'
    - env:
        WINGET_DISABLE_INTERACTIVE: "1"

install_powershell:
  cmd.run:
    - name: {{ winget_path }} install Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity
    - shell: powershell
    - runas: {{ winget_user }}
    - env:
        WINGET_DISABLE_INTERACTIVE: "1"
    - unless: Get-Command pwsh -ErrorAction SilentlyContinue
    - onlyif: Test-Path '{{ winget_path }}'
    - require:
      - cmd: winget_bootstrap

install_git:
  cmd.run:
    - name: {{ winget_path }} install Git.Git --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity
    - shell: powershell
    - runas: {{ winget_user }}
    - env:
        WINGET_DISABLE_INTERACTIVE: "1"
    - unless: Get-Command git -ErrorAction SilentlyContinue
    - onlyif: Test-Path '{{ winget_path }}'
    - require:
      - cmd: winget_bootstrap


# ============================================================================
# C:\opt Directory Structure and Permissions
# ============================================================================

opt_directory:
  file.directory:
    - name: C:\opt
    - makedirs: True

opt_cozy_directory:
  file.directory:
    - name: C:\opt\cozy
    - makedirs: True
    - require:
      - file: opt_directory

# Grant cozyusers full control on C:\opt (inheritable)
opt_acl_cozyusers:
  cmd.run:
    - name: |
        icacls "C:\opt" /grant "cozyusers:(OI)(CI)F" /t /c
    - shell: cmd
    - require:
      - file: opt_directory

# ============================================================================
# Environment Variable Management
# ============================================================================

# Force environment broadcast after PATH changes
# Salt doesn't send WM_SETTINGCHANGE, so services won't see updated PATH
# Uses rundll32 to broadcast WM_SETTINGCHANGE without C# interop
broadcast_env_change:
  cmd.run:
    - name: rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1 ,True
    - shell: cmd
    - onchanges_any:
      - cmd: opt_acl_cozyusers
