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

# Add {{ username }} to Windows groups using PowerShell
# Salt's user.present groups parameter has a bug on Windows (ValueError: list.remove)
# Use PowerShell Add-LocalGroupMember cmdlet instead
{{ username }}_add_to_groups:
  cmd.run:
    - name: |
        {% for group in userdata.get('windows_groups', ['Users']) %}
        Add-LocalGroupMember -Group "{{ group }}" -Member "{{ username }}" -ErrorAction SilentlyContinue
        {% endfor %}
    - shell: pwsh
    - require:
      - user: {{ username }}_user

# Create {{ username }} home directory
{{ username }}_home_directory:
  file.directory:
    - name: C:\Users\{{ username }}
    - user: {{ username }}
    - makedirs: True
    - require:
      - user: {{ username }}_user

{% set ssh_keys = userdata.get('ssh_keys', []) %}
{% set windows_groups = userdata.get('windows_groups', ['Users']) %}
{% set is_admin = 'Administrators' in windows_groups %}
{% if ssh_keys %}
{% if is_admin %}
# Admin user {{ username }}: append keys to administrators_authorized_keys
{{ username }}_admin_ssh_dir:
  file.directory:
    - name: C:\ProgramData\ssh
    - makedirs: True

{{ username }}_admin_ssh_keys:
  file.append:
    - name: C:\ProgramData\ssh\administrators_authorized_keys
    - text:
{% for key in ssh_keys %}
      - "{{ key }}"
{% endfor %}
    - require:
      - file: {{ username }}_admin_ssh_dir
      - user: {{ username }}_user
{% else %}
# Non-admin user {{ username }}: append keys to user's .ssh/authorized_keys
{{ username }}_ssh_directory:
  file.directory:
    - name: C:\Users\{{ username }}\.ssh
    - user: {{ username }}
    - makedirs: True
    - require:
      - file: {{ username }}_home_directory

{{ username }}_ssh_keys:
  file.append:
    - name: C:\Users\{{ username }}\.ssh\authorized_keys
    - text:
{% for key in ssh_keys %}
      - "{{ key }}"
{% endfor %}
    - require:
      - file: {{ username }}_ssh_directory
{% endif %}
{% endif %}

{% endfor %}
