# Windows Bootstrap State
# "Make you behave like a predictable Windows target"
# Run EARLY - before normal states, after script state gets Salt talking
# See TODO.md for full context

# ============================================================================
# WinRM Configuration (Salt communication foundation)
# ============================================================================

winrm_disable_credssp_client:
  cmd.run:
    - name: winrm set winrm/config/client/auth @{CredSSP="false"}
    - shell: cmd

winrm_disable_credssp_service:
  cmd.run:
    - name: winrm set winrm/config/service/auth @{CredSSP="false"}
    - shell: cmd

winrm_allow_unencrypted_service:
  cmd.run:
    - name: winrm set winrm/config/service @{AllowUnencrypted="true"}
    - shell: cmd

winrm_allow_unencrypted_client:
  cmd.run:
    - name: winrm set winrm/config/client @{AllowUnencrypted="true"}
    - shell: cmd

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

powershell_execution_policy:
  cmd.run:
    - name: Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
    - shell: powershell

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
# Package mangement configuration 
# ============================================================================
winget_bootstrap:
  cmd.run:
    - name: >
        winget source enable msstore --accept-source-agreements --disable-interactivity;
        winget source update --disable-interactivity
    - shell: powershell
    - runas: User #TODO: detect executing user
    - env:
        WINGET_DISABLE_INTERACTIVE: "1"

# ============================================================================
# PWSH install 
# ============================================================================
install_powershell:
  cmd.run:
    - name: >
        winget install Microsoft.PowerShell --disable-interactivity
    - shell: powershell
    - runas: User #TODO: detect executing user
    - env:
        WINGET_DISABLE_INTERACTIVE: "1"


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
