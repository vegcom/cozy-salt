# Linux user management
# Groups, skel, and sudoers are in linux.groups (runs first)
# Requires: linux.groups (groups + skel), linux.install (shell_packages)

{%- from "_macros/dotfiles.sls" import user_dotfile %}
{% set users = salt['pillar.get']('users', {}) %}

# Iterate over users from pillar and create each one
{% for username, userdata in users.items() %}
{% set user_groups = userdata.get('linux_groups', ['cozyusers']) %}
{% set user_shell = userdata.get('shell', '/bin/bash') %}

# Create {{ username }} user
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - home: {{ userdata.get('home_prefix', '/home') }}/{{ username }}
    - shell: {{ user_shell }}
    - groups: {{ user_groups | tojson }}
    - remove_groups: False
    {% if userdata.get('uid') %}- uid: {{ userdata.uid }}
    - allow_uid_change: True{% endif %}
    {% if userdata.get('gid') %}- gid: {{ userdata.gid }}
    - allow_gid_change: True{% endif %}
    - order: 10
    - require:
      - file: skel_files
{% for group in user_groups %}
      - group: {{ group }}_group
{% endfor %}
{% if userdata.get('gid') %}
      - group: {{ username }}_primary_group
{% endif %}


# Create {{ username }} home directory
{% set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
{{ username }}_home_directory:
  file.directory:
    - name: {{ user_home }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0755"
    - makedirs: True
    - follow_symlinks: False
    - exclude_pat:
      - E@\.npm.*
      - E@\.cache.*
      - E@node_modules.*
      - E@\.local/share/Trash.*
    - require:
      - user: {{ username }}_user

# Deploy user dotfiles via macro
{{ user_dotfile(username, user_home, '.bashrc', 'salt://linux/files/etc-skel/.bashrc') }}
{{ user_dotfile(username, user_home, '.zshrc', 'salt://linux/files/etc-skel/.zshrc') }}
{{ user_dotfile(username, user_home, '.profile', 'salt://linux/files/etc-skel/.profile') }}

{% set ssh_keys = userdata.get('ssh_keys', []) %}
{% if ssh_keys %}
# Create {{ username }} .ssh directory
{{ username }}_ssh_directory:
  file.directory:
    - name: {{ user_home }}/.ssh
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0700"
    - makedirs: True
    - require:
      - file: {{ username }}_home_directory

# Append {{ username }} SSH keys (does not overwrite existing keys)
{% for key in ssh_keys %}
{{ username }}_ssh_key_{{ loop.index }}:
  ssh_auth.present:
    - user: {{ username }}
    - name: {{ key }}
    - require:
      - file: {{ username }}_ssh_directory
{% endfor %}
{% endif %}

# Create {{ username }} scratch mount
scratch_mount_{{ username }}:
  file.managed:
    - name: /etc/systemd/system/home-{{ username }}-scratch.mount
    - source: salt://_templates/scratch-mount.jinja
    - username: {{ username }}
    - template: jinja
    - mode: "0644"
    - makedirs: True

# Create {{ username }} scratch automount
{{ username }}_scratch_automount:
  file.managed:
    - name: /etc/systemd/system/home-{{ username }}-scratch.automount
    - source: salt://_templates/scratch-automount.jinja
    - username: {{ username }}
    - template: jinja
    - mode: "0644"
    - makedirs: True

# Create {{ username }} scratch directory
{{ username }}_scratch_directory:
  file.directory:
    - name: {{ user_home }}/scratch
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0700"
    - makedirs: True
    - require:
      - file: {{ username }}_home_directory

scratch_automount_enable_{{ username }}:
  service.enabled:
    - name: home-{{ username }}-scratch.automount
    - file: {{ username }}_scratch_directory

# SMB mounts for {{ username }} (from pillar smb:{share_name})
# Uses systemd .mount/.automount units for lazy mounting + network resilience
{% set smb_shares = salt['pillar.get']('smb', {}) %}
{% if userdata.get('uid') and smb_shares %}
{% for share_name, share_config in smb_shares.items() %}
{% set mountpoint = share_config.get('mountpoint', share_name) %}
{% set mount_path = user_home ~ '/' ~ mountpoint %}
{% set creds_path = share_config.get('credentials_path', '/etc/samba/creds') %}
{% set creds_file = creds_path ~ '/' ~ username %}
{% set unit_name = 'home-' ~ username ~ '-' ~ mountpoint %}

{{ username }}_smb_creds_dir:
  file.directory:
    - name: {{ creds_path }}
    - mode: "0700"
    - makedirs: True

{% if userdata.get('smb_password') %}
{{ username }}_smb_creds_file:
  file.managed:
    - name: {{ creds_file }}
    - contents: |
        username={{ userdata.get('smb_username', username) }}
        password={{ userdata.smb_password }}
        {% if userdata.get('smb_domain') %}domain={{ userdata.smb_domain }}{% endif %}
    - mode: "0600"
    - user: root
    - group: root
    - require:
      - file: {{ username }}_smb_creds_dir
{% endif %}

{{ username }}_smb_{{ share_name }}_dir:
  file.directory:
    - name: {{ mount_path }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0750"
    - makedirs: True
    - require:
      - file: {{ username }}_home_directory

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
{% if userdata.get('smb_password') %}
      - file: {{ username }}_smb_creds_file
{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
