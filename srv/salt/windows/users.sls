# Windows user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates managed users with appropriate Windows groups (Administrators, Users)

# Profile health check - detect corrupted/temp profiles before proceeding
# Temp profiles have .MACHINENAME suffix (e.g., user.DESKTOP-ABC123)
windows_profile_health_check:
  cmd.run:
    - name: |
        $tempProfiles = Get-ChildItem C:\Users -Directory -ErrorAction SilentlyContinue |
          Where-Object { $_.Name -match '\.\w+-\w+$' }
        if ($tempProfiles) {
          Write-Host "WARNING: Detected temporary/corrupted profiles:"
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
    - shell: pwsh
    - order: 1

{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', []) %}

# Iterate over managed_users only (admin excluded on Windows, uses built-in Administrator)
{% for username in managed_users %}
{% set userdata = users.get(username, {}) %}
# Create {{ username }} user on Windows
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}

# Force profile creation by running a command as the user
# This ensures Windows creates the profile before we try to manage files in it
{{ username }}_initialize_profile:
  cmd.run:
    - name: whoami
    - runas: {{ username }}
    - shell: cmd
    - require:
      - user: {{ username }}_user

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
