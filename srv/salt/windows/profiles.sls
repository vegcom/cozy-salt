# Windows PowerShell 7 System-Wide Profile Deployment
# Deploys comprehensive PowerShell configuration to C:\Program Files\PowerShell\7
# Profile includes: init, time, logging, aliases, functions, modules, npm, conda, choco, code, starship

{% set pwsh_profile_dir = 'C:\\Program Files\\PowerShell\\7' %}

# Create PowerShell 7 profile directory structure
powershell_profile_directory:
  file.directory:
    - name: {{ pwsh_profile_dir }}
    - makedirs: True

# Deploy main profile and config files recursively
# Mirrors directory structure: config.d/, starship.toml, Microsoft.PowerShell_profile.ps1
powershell_profile_files:
  file.recurse:
    - name: {{ pwsh_profile_dir }}
    - source: salt://windows/files/PROFILE.AllUsersCurrentHost/
    - makedirs: True
    - require:
      - file: powershell_profile_directory

# Ensure profile is readable by all users and writable by administrators
# This state depends on the profile being deployed first
powershell_profile_deployed:
  cmd.run:
    - name: icacls "{{ pwsh_profile_dir }}" /grant:r "Users:(OI)(CI)(R)" /grant:r "Administrators:(OI)(CI)(F)" /t /q
    - shell: cmd
    - require:
      - file: powershell_profile_files
    - onchanges:
      - file: powershell_profile_files
