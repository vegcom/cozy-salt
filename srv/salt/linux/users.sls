# Linux user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Dynamically creates groups from user linux_groups definitions
# Managed users can run docker and sudo commands without password

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
{% for group in all_groups %}
{{ group }}_group:
  group.present:
    - name: {{ group }}
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
    - require:
      - user: {{ username }}_user

# Deploy {{ username }} .bashrc
{{ username }}_bashrc:
  file.managed:
    - name: {{ user_home }}/.bashrc
    - source: salt://linux/files/etc-skel/.bashrc
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0644"
    - require:
      - file: {{ username }}_home_directory

{% set ssh_keys = userdata.get('ssh_keys', []) %}
{% if ssh_keys %}
# Create {{ username }} .ssh directory
{{ username }}_ssh_directory:
  file.directory:
    - name: {{ userdata.get('home_prefix', '/home') }}/{{ username }}/.ssh
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
