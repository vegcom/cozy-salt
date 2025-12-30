# Windows user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates managed users with appropriate Windows groups (Administrators, Users)

{% set users = salt['pillar.get']('users', {}) %}

# Iterate over users from pillar and create each one on Windows
{% for username, userdata in users.items() %}
# Create {{ username }} user on Windows
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - groups: {{ userdata.get('windows_groups', ['Users']) | tojson }}

# Create {{ username }} home directory
{{ username }}_home_directory:
  file.directory:
    - name: C:\Users\{{ username }}
    - user: {{ username }}
    - makedirs: True
    - require:
      - user: {{ username }}_user

{% endfor %}
