# Linux SMB mount management
# Deploys per-user systemd .mount/.automount units for lazy CIFS mounting
# Pillar: smb:{share_name}:{device, mountpoint, opts} + users:{username}:{smb_password, smb_username, smb_domain, uid, gid}

{%- set users = salt['pillar.get']('users', {}) %}
{%- set smb_shares = salt['pillar.get']('smb', {}) %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

{%- for username, userdata in users.items() %}
{%- if userdata.get('uid') and smb_shares %}
{%- set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
{%- set creds_path = '/etc/samba/creds' %}
{%- set creds_file = creds_path ~ '/' ~ username %}

{{ username }}_smb_creds_dir:
  file.directory:
    - name: {{ creds_path }}
    - mode: "0700"
    - makedirs: True

{%- if userdata.get('smb_password') %}
{{ username }}_smb_creds_file:
  file.managed:
    - name: {{ creds_file }}
    - contents: |
        username={{ userdata.get('smb_username', username) }}
        password={{ userdata.smb_password }}
        {%- if userdata.get('smb_domain') %}
        domain={{ userdata.smb_domain }}
        {%- endif %}
    - mode: "0600"
    - user: root
    - group: root
    - require:
      - file: {{ username }}_smb_creds_dir
{%- endif %}

{%- for share_name, share_config in smb_shares.items() %}
{%- set mountpoint = share_config.get('mountpoint', share_name) %}
{%- set mount_path = user_home ~ '/' ~ mountpoint %}
{%- set unit_name = 'home-' ~ username ~ '-' ~ mountpoint %}

{{ username }}_smb_{{ share_name }}_dir:
  file.directory:
    - name: {{ mount_path }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0755"
    - makedirs: True

# Systemd mount unit for {{ share_name }}
{{ username }}_smb_{{ share_name }}_mount_unit:
  file.managed:
    - name: /etc/systemd/system/{{ unit_name }}.mount
    - source: salt://_templates/smb-mount.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True
    - username: {{ username }}
    - share_name: {{ share_name }}
    - mountpoint: {{ mountpoint }}
    - device: {{ share_config.device }}
    - credentials_file: {{ creds_file }}
    - uid: {{ userdata.uid }}
    - gid: {{ userdata.gid }}
    - mount_opts: {{ share_config.get('opts', 'vers=3.0') }}
    - require:
      - file: {{ username }}_smb_{{ share_name }}_dir

# Systemd automount unit for {{ share_name }}
{{ username }}_smb_{{ share_name }}_automount_unit:
  file.managed:
    - name: /etc/systemd/system/{{ unit_name }}.automount
    - source: salt://_templates/smb-automount.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True
    - username: {{ username }}
    - share_name: {{ share_name }}
    - mountpoint: {{ mountpoint }}
    - require:
      - file: {{ username }}_smb_{{ share_name }}_mount_unit

# Enable automount (lazy mount on access)
{{ username }}_smb_{{ share_name }}_automount_enable:
  service.enabled:
    - name: {{ unit_name }}.automount
    - require:
      - file: {{ username }}_smb_{{ share_name }}_automount_unit
{%- if userdata.get('smb_password') %}
      - file: {{ username }}_smb_creds_file
{%- endif %}
{%- endfor %}
{%- endif %}
{%- endfor %}
