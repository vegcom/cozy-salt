# Windows PowerShell 7 System-Wide Profile Deployment
# Fetches comprehensive PowerShell configuration from cozy-pwsh.git
# Profile includes: init, time, logging, aliases, functions, modules, npm, conda, choco, code, starship
# See docs/modules/windows-profiles.md for configuration
# Requires: srv/salt/common/gitconfig.sls (deploy_git_credentials_system)

{% set pwsh_profile_dir = salt['pillar.get']('paths:powershell_7_profile', 'C:\\Program Files\\PowerShell\\7') %}

# Create PowerShell 7 profile directory structure
powershell_profile_directory:
  file.directory:
    - name: {{ pwsh_profile_dir }}
    - makedirs: True

# Deploy PowerShell profile via git (clone cozy-pwsh.git)
# Uses .git-credentials deployed via common/gitconfig.sls (deploy_git_credentials_system)
# SYSTEM home: C:\Windows\System32\config\systemprofile\.git-credentials
powershell_profile_files:
  git.latest:
    - name: https://github.com/vegcom/cozy-pwsh.git
    - target: {{ pwsh_profile_dir }}
    - branch: main
    - force_clone: True
    - force_reset: True
    - require:
      - file: powershell_profile_directory

# Ensure profile is readable by all users and writable by administrators
# This state depends on the profile being deployed first
powershell_profile_deployed:
  cmd.run:
    - name: icacls "{{ pwsh_profile_dir }}" /grant:r "Users:(OI)(CI)(R)" /grant:r "Administrators:(OI)(CI)(F)" /t /q
    - shell: cmd
    - require:
      - git: powershell_profile_files
    - onchanges:
      - git: powershell_profile_files
