# Linux user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates system groups (cozyusers, docker) for user membership
# Creates managed users with appropriate groups (cozyusers, sudo, docker)
# Managed users can run docker and sudo commands without password

{% set users = salt['pillar.get']('users', {}) %}

# Create system groups (must exist before users are added to them)
# Using order: 1 to ensure groups are created very early in state run
docker_group:
  group.present:
    - name: docker
    - order: 1

# Create cozyusers group (for group-based permissions on shared tools)
cozyusers_group:
  group.present:
    - name: cozyusers
    - order: 2
    - require:
      - group: docker_group

# Iterate over users from pillar and create each one
{% for username, userdata in users.items() %}
# Create {{ username }} user
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - home: {{ userdata.get('home_prefix', '/home') }}/{{ username }}
    - shell: {{ userdata.get('shell', '/bin/bash') }}
    - groups: {{ userdata.get('linux_groups', ['cozyusers']) | tojson }}
    - remove_groups: False
    - order: 10
    - require:
      - group: cozyusers_group
      - group: docker_group

# Create {{ username }} home directory
{{ username }}_home_directory:
  file.directory:
    - name: {{ userdata.get('home_prefix', '/home') }}/{{ username }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - require:
      - user: {{ username }}_user

{% set ssh_keys = userdata.get('ssh_keys', []) %}
{% if ssh_keys %}
# Create {{ username }} .ssh directory
{{ username }}_ssh_directory:
  file.directory:
    - name: {{ userdata.get('home_prefix', '/home') }}/{{ username }}/.ssh
    - user: {{ username }}
    - group: {{ username }}
    - mode: 700
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
    - mode: 440
    - user: root
    - group: root
    - makedirs: True
