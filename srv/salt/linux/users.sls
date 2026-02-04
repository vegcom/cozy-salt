# Linux user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Dynamically creates groups from user linux_groups definitions
# Managed users can run docker and sudo commands without password

{%- from "_macros/dotfiles.sls" import user_dotfile %}
{% set users = salt['pillar.get']('users', {}) %}

# ============================================================================
# SKELETON: Must run BEFORE user creation (user.present copies /etc/skel)
# ============================================================================
skel_files:
  file.recurse:
    - name: /etc/skel
    - source: salt://linux/files/etc-skel
    - include_empty: True
    - clean: False
    - order: 1

# Collect all unique groups from user definitions
{% set all_groups = [] %}
{% for username, userdata in users.items() %}
  {% for group in userdata.get('linux_groups', ['cozyusers']) %}
    {% if group not in all_groups %}
      {% do all_groups.append(group) %}
    {% endif %}
  {% endfor %}
{% endfor %}

# Create groups dynamically (must exist before users are added)
# GIDs from pillar groups:{name}:gid or user uid for primary groups
{% set pillar_groups = salt['pillar.get']('groups', {}) %}
{% for group in all_groups %}
{{ group }}_group:
  group.present:
    - name: {{ group }}
    {% if pillar_groups.get(group, {}).get('gid') %}- gid: {{ pillar_groups[group].gid }}{% endif %}
    - order: 1
{% endfor %}

# Iterate over users from pillar and create each one
{% for username, userdata in users.items() %}
{% set user_groups = userdata.get('linux_groups', ['cozyusers']) %}
# Create {{ username }} user
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - home: {{ userdata.get('home_prefix', '/home') }}/{{ username }}
    - shell: {{ userdata.get('shell', '/bin/bash') }}
    - groups: {{ user_groups | tojson }}
    - remove_groups: False
    {% if userdata.get('uid') %}- uid: {{ userdata.uid }}{% endif %}
    {% if userdata.get('gid') %}- gid: {{ userdata.gid }}{% endif %}
    - order: 10
    - require:
      - file: skel_files
{% for group in user_groups %}
      - group: {{ group }}_group
{% endfor %}

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
    - recurse:
      - user
      - group
    - require:
      - user: {{ username }}_user

# Deploy user dotfiles via macro
{{ user_dotfile(username, user_home, '.bashrc', 'salt://linux/files/etc-skel/.bashrc') }}
{{ user_dotfile(username, user_home, '.zshrc', 'salt://linux/files/etc-skel/.zshrc') }}
{{ user_dotfile(username, user_home, '.config/systemd/user/tmux@.service', 'salt://linux/files/etc-skel/.config/systemd/user/tmux@.service') }}

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
    - user_name: {{ username }}
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
{% endfor %}

# Create sudoers file for cozyusers group (NOPASSWD for all commands)
cozyusers_sudoers:
  file.managed:
    - name: /etc/sudoers.d/cozyusers
    - contents: |
        # Allow cozyusers group to run all commands without password
        %cozyusers ALL=(ALL:ALL) NOPASSWD: ALL
    - mode: "0440"
    - user: root
    - group: root
    - makedirs: True
