# Linux user management
# Groups, skel, and sudoers are in linux.groups (runs first)
# Requires: linux.groups (groups + skel), linux.install (shell_packages)

{%- from "_macros/dotfiles.sls" import user_dotfile %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

include:
  - linux.groups

# Iterate over users from pillar and create each one
{%- for username, userdata in users.items() %}
{%- set user_groups = userdata.get('linux_groups', ['cozyusers']) %}
{%- set user_shell = userdata.get('shell', '/bin/bash') %}

# Create {{ username }} user
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - home: {{ userdata.get('home_prefix', '/home') }}/{{ username }}
    - shell: {{ user_shell }}
    - groups: {{ user_groups | tojson }}
    - remove_groups: False
    {%- if userdata.get('uid') %}
    - uid: {{ userdata.uid }}
    - allow_uid_change: True
    {%- endif %}
    {%- if userdata.get('gid') %}
    - gid: {{ userdata.gid }}
    - allow_gid_change: True
    {%- endif %}
    - order: 10
    - require:
      - file: skel_files
{%- for group in user_groups %}
      - group: {{ group }}_group
{%- endfor %}
{%- if userdata.get('gid') %}
      - group: {{ username }}_primary_group
{%- endif %}

{%- if not is_container %}
loginctl_linger_{{ username }}:
  cmd.run:
    - name: loginctl enable-linger {{ username }}
    - unless: loginctl show-user {{ username }} | grep 'Linger=yes'
{%- endif %}

# Create {{ username }} home directory
{%- set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
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
{{ user_dotfile(username, user_home, '.config/starship.toml', 'https://raw.githubusercontent.com/vegcom/Starship-Twilite/main/starship.toml', skip_verify=true) }}

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
{%- if not salt['file.file_exists'](user_home) %}
    - require:
      - file: {{ username }}_home_directory
{%- endif %}

{%- if not is_container %}
scratch_automount_enable_{{ username }}:
  service.enabled:
    - name: home-{{ username }}-scratch.automount
    - require:
      - file: {{ username }}_scratch_directory
{%- endif %}

{%- endfor %}
