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
  file.symlink:
    - name: '{{ pwsh_profile_dir }}\Microsoft.PowerShell_profile.ps1'
    - target: '{{ repo_path }}\Microsoft.PowerShell_profile.ps1'
    - force: True
    - require:
      - git: pwsh_profile_repo

# Symlink config.d directory
pwsh_config_d_symlink:
  file.symlink:
    - name: '{{ pwsh_profile_dir }}\config.d'
    - target: '{{ repo_path }}\config.d'
    - force: True
    - require:
      - git: pwsh_profile_repo

# Ensure repo is readable by all users
pwsh_profile_acl:
  cmd.run:
    - name: icacls "{{ repo_path }}" /grant:r "Users:(OI)(CI)(R)" /grant:r "Administrators:(OI)(CI)(F)" /t /q
    - shell: cmd
    - require:
      - git: pwsh_profile_repo
    - onchanges:
      - git: pwsh_profile_repo
