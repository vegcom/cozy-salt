# Windows SMB mount management
# Calls mount-share.ps1 per user per share, gated on smb_password in pillar
# Pillar: smb:{share_name}:{device, mountpoint} + users:{username}:{smb_password, smb_username, smb_domain}

{%- set users = salt['pillar.get']('users', {}) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- set smb_shares = salt['pillar.get']('smb', {}) %}

{%- for username in managed_users %}
{%- set userdata = users.get(username, {}) %}
{%- if userdata.get('smb_password') and smb_shares %}

{%- for share_name, share_config in smb_shares.items() %}
{%- set device = share_config.get('device', '') %}
{%- set parts = device.lstrip('/').split('/') %}
{%- set share_server = parts[0] %}
{%- set share_share = parts[1] if parts | length > 1 else share_name %}
{%- set mountpoint = share_config.get('mountpoint', share_name) %}

{{ username }}_smb_{{ share_name }}:
  cmd.run:
    - name: >-
        C:/opt/cozy/bin/mount-share.ps1
        -ShareServer {{ share_server }}
        -ShareName {{ share_share }}
        -ShareUser {{ userdata.get('smb_username', username) }}
        -SharePass '{{ userdata.smb_password }}'
    - shell: powershell
    - runas: {{ username }}
    - creates: C:/Users/{{ username }}/{{ mountpoint }}
{%- endfor %}
{%- endif %}
{%- endfor %}
