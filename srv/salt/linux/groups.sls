# Linux group management
# Runs BEFORE linux.install so install states can require cozyusers group
# Runs BEFORE linux.users so users can require groups + shell_packages

{% set users = salt['pillar.get']('users', {}) %}
{% set pillar_groups = salt['pillar.get']('groups', {}) %}

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

# Create user primary groups (must run before dynamic group loop)
# GID pinned per-user in pillar users/{username}.gid
{% for username, userdata in users.items() %}
{% if userdata.get('gid') %}
{{ username }}_primary_group:
  group.present:
    - name: {{ username }}
    - gid: {{ userdata.gid }}
    - order: 0
{% endif %}
{% endfor %}

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
# GIDs from pillar groups:{name}:gid — system groups get OS-assigned GID
{% for group in all_groups %}
{{ group }}_group:
  group.present:
    - name: {{ group }}
    {% if pillar_groups.get(group, {}).get('gid') %}- gid: {{ pillar_groups[group].gid }}{% endif %}
    - order: 1
{% endfor %}

# sudoers for cozyusers group (NOPASSWD)
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
    - require:
      - group: cozyusers_group

{% if "nopasswdlogin" in all_groups %}
# sudoers for nopasswdlogin group
nopasswdlogin_sudoers:
  file.managed:
    - name: /etc/sudoers.d/nopasswdlogin
    - contents: |
        # Allow nopasswdlogin group to run all commands with password
        %nopasswdlogin ALL=(ALL:ALL) ALL
    - mode: "0440"
    - user: root
    - group: root
    - makedirs: True
    - require:
      - group: nopasswdlogin_group
{% endif %}
