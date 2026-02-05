# Windows PowerShell 7 System-Wide Profile Deployment
# Clones cozy-pwsh.git to C:\opt\cozy\cozy-pwsh, symlinks profile into PowerShell 7 dir
# See docs/modules/windows-profiles.md for configuration

{% from '_macros/windows.sls' import get_winget_user with context %}

{% set pwsh_profile_dir = salt['pillar.get']('paths:powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}
{% set repo_path = 'C:\\opt\\cozy\\cozy-pwsh' %}
{% set winget_user = get_winget_user() %}

# Clone cozy-pwsh repo to C:\opt\cozy-pwsh
pwsh_profile_repo:
  git.latest:
    - name: https://github.com/vegcom/cozy-pwsh.git
    - target: {{ repo_path }}
    - branch: main
    - force_reset: True
    - runas: {{ winget_user }}

# Symlink profile file
pwsh_profile_symlink:
  cmd.run:
    - name: |
        if (Test-Path "{{ pwsh_profile_dir }}\Microsoft.PowerShell_profile.ps1") {
          Remove-Item "{{ pwsh_profile_dir }}\Microsoft.PowerShell_profile.ps1" -Force
        }
        New-Item -ItemType SymbolicLink -Path "{{ pwsh_profile_dir }}\Microsoft.PowerShell_profile.ps1" -Target "{{ repo_path }}\Microsoft.PowerShell_profile.ps1"
    - shell: powershell
    - require:
      - git: pwsh_profile_repo
    # - unless: >
    #     (Get-Item "{{ pwsh_profile_dir }}\Microsoft.PowerShell_profile.ps1" -ErrorAction SilentlyContinue).LinkType -eq 'SymbolicLink'

# Symlink config.d directory
pwsh_config_d_symlink:
  cmd.run:
    - name: |
        if (Test-Path "{{ pwsh_profile_dir }}\config.d") {
          Remove-Item "{{ pwsh_profile_dir }}\config.d" -Recurse -Force
        }
        New-Item -ItemType SymbolicLink -Path "{{ pwsh_profile_dir }}\config.d" -Target "{{ repo_path }}\config.d"
    - shell: powershell
    - require:
      - git: pwsh_profile_repo
    # - unless: >
    #     (Get-Item "{{ pwsh_profile_dir }}\config.d" -ErrorAction SilentlyContinue).LinkType -eq 'SymbolicLink'

# Ensure repo is readable by all users
pwsh_profile_acl:
  cmd.run:
    - name: icacls "{{ repo_path }}" /grant:r "Users:(OI)(CI)(R)" /grant:r "Administrators:(OI)(CI)(F)" /t /q
    - shell: cmd
    - require:
      - git: pwsh_profile_repo
    - onchanges:
      - git: pwsh_profile_repo
