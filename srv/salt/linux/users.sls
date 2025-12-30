# Linux user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates cozyusers group for shared resource access
# Creates managed users with appropriate groups (cozyusers, sudo, docker)
# Managed users can run docker and sudo commands without password

{% set users = salt['pillar.get']('users', {}) %}

# Create cozyusers group (for group-based permissions on shared tools)
cozyusers_group:
  group.present:
    - name: cozyusers

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
    - require:
      - group: cozyusers_group

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
