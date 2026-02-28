# Windows user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates managed users with appropriate Windows groups (Administrators, Users)

{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

# Profile health check - detect corrupted/temp profiles before proceeding
# Checks for folders like admin.rocket, vegcom.DESKTOP-ABC123 where base name is a managed user
windows_profile_health_check:
  cmd.run:
    - name: |
        $managedUsers = @({{ managed_users | map('tojson') | join(', ') }})
        $tempProfiles = Get-ChildItem C:\Users -Directory -ErrorAction SilentlyContinue |
          Where-Object {
            if ($_.Name -match '^([^.]+)\.(.+)$') {
              $baseUser = $matches[1]
              $managedUsers -contains $baseUser
            } else { $false }
          }
        if ($tempProfiles) {
          Write-Host "WARNING: Detected temporary/corrupted profiles for managed users:"
          $tempProfiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
          Write-Host ""
          Write-Host "These indicate profile corruption (SID mismatch or failed profile load)."
          Write-Host "Fix manually before proceeding:"
          Write-Host "  1. Check HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
          Write-Host "  2. Remove orphaned registry entries"
          Write-Host "  3. Delete or rename duplicate profile folders"
          exit 1
        }
        Write-Host "Profile health check passed - no temp profiles detected"
    - shell: powershell
    - order: 1

# Iterate over managed_users only (admin excluded on Windows, uses built-in Administrator)
{% for username in managed_users %}
{% set userdata = users.get(username, {}) %}
# Create {{ username }} user on Windows
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - password: {{ userdata.get('password', '') }}
    - password_lock: False
    - empty_password: {{ 'True' if not userdata.get('password') else 'False' }}
    - enforce_password: {{ 'True' if userdata.get('password') else 'False' }}
    - win_logonscript: C:\\opt\cozy\bin\login.ps1
    - win_profile: C:\Users\{{ username }}\

# Force profile creation by running a command as the user
# Must run BEFORE registry fix — Windows needs a stable profile load first
# Modifying ProfileList before provisioning completes causes .bak SID keys
{{ username }}_initialize_profile:
  cmd.run:
    - name: whoami
    - runas: {{ username }}
    - shell: cmd
    - require:
      - user: {{ username }}_user

# Post-check: fix ProfileList registry if path is wrong
# Runs AFTER profile is stable to avoid .bak rename (SID conflict)
{{ username }}_fix_profile_path:
  cmd.run:
    - name: |
        $username = '{{ username }}'
        $expectedPath = "C:\Users\$username"

        # Get user SID
        $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
        if (-not $user) { Write-Host "User not found"; exit 0 }
        $sid = $user.SID.Value

        # Check/fix ProfileList registry
        $profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
        if (Test-Path $profileListPath) {
          $currentPath = (Get-ItemProperty $profileListPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
          if ($currentPath -and $currentPath -ne $expectedPath) {
            Write-Host "Fixing profile path: $currentPath -> $expectedPath"
            Set-ItemProperty $profileListPath -Name ProfileImagePath -Value $expectedPath
          }
        } else {
          # Create ProfileList entry if missing
          Write-Host "Creating ProfileList entry for $username"
          New-Item -Path $profileListPath -Force | Out-Null
          Set-ItemProperty $profileListPath -Name ProfileImagePath -Value $expectedPath
          Set-ItemProperty $profileListPath -Name Flags -Value 0 -Type DWord
          Set-ItemProperty $profileListPath -Name State -Value 0 -Type DWord
        }
    - shell: powershell
    - require:
      - user: {{ username }}_user
      - cmd: {{ username }}_initialize_profile

{% if userdata.get('smb_password') %}
{{ username }}_mount_git:
  cmd.run:
    - name: |
        pwsh -ExecutionPolicy Bypass -File C:\opt\cozy\bin\mount-share.ps1
          -ShareServer COZY-SHARE
          -ShareName Git
          -ShareUser {{ username }}
          -SharePass {{ userdata.get('smb_password', '') }}
    - runas: {{ username }}
{% endif %}

# Add {{ username }} to Windows groups using PowerShell
# Salt's user.present groups parameter has a bug on Windows (ValueError: list.remove)
# Use PowerShell Add-LocalGroupMember cmdlet instead
{{ username }}_add_to_groups:
  cmd.run:
    - name: |
        {% for group in userdata.get('windows_groups', ['Users']) %}
        Add-LocalGroupMember -Group "{{ group }}" -Member "{{ username }}" -ErrorAction SilentlyContinue
        {% endfor %}
    - shell: pwsh
    - require:
      - user: {{ username }}_user

{% set ssh_keys = userdata.get('ssh_keys', []) %}
{% set windows_groups = userdata.get('windows_groups', ['Users']) %}
{% set is_admin = 'Administrators' in windows_groups %}
{% if ssh_keys %}
{% if is_admin %}
# Admin user {{ username }}: append keys to administrators_authorized_keys
{{ username }}_admin_ssh_dir:
  file.directory:
    - name: C:\ProgramData\ssh
    - makedirs: True

{{ username }}_admin_ssh_keys:
  file.append:
    - name: C:\ProgramData\ssh\administrators_authorized_keys
    - text:
{% for key in ssh_keys %}
      - "{{ key }}"
{% endfor %}
    - require:
      - file: {{ username }}_admin_ssh_dir
      - user: {{ username }}_user
{% else %}
# Non-admin user {{ username }}: append keys to user's .ssh/authorized_keys
{{ username }}_ssh_directory:
  file.directory:
    - name: C:\Users\{{ username }}\.ssh
    - user: {{ username }}
    - makedirs: True
    - require:
      - cmd: {{ username }}_initialize_profile

# Ensure authorized_keys exists with correct ownership
{{ username }}_authorized_keys_file:
  file.managed:
    - name: C:\Users\{{ username }}\.ssh\authorized_keys
    - user: {{ username }}
    - replace: False
    - require:
      - file: {{ username }}_ssh_directory

{{ username }}_ssh_keys:
  file.append:
    - name: C:\Users\{{ username }}\.ssh\authorized_keys
    - text:
{% for key in ssh_keys %}
      - "{{ key }}"
{% endfor %}
    - require:
      - file: {{ username }}_authorized_keys_file
{% endif %}
{% endif %}

{% endfor %}
