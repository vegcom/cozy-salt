# Windows user and group management
# Iterates over users defined in pillar (srv/pillar/common/users.sls)
# Creates managed users with appropriate Windows groups (Administrators, Users)

{%- set users = salt['pillar.get']('users', {}) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{%- for username in managed_users %}
{%- set userdata = users.get(username, {}) %}
{{ username }}_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ userdata.get('fullname', username) }}
    - password: {{ userdata.get('password', '') }}
    - password_lock: False
    - empty_password: {{ 'True' if not userdata.get('password') else 'False' }}
    - enforce_password: {{ 'True' if userdata.get('password') else 'False' }}
    - win_logonscript: C:\\opt\cozy\bin\login.ps1

{%- for group in userdata.get('windows_groups', ['Users']) %}
{{ username }}_add_to_{{ group | lower | replace(' ', '_') }}:
  group.present:
    - name: {{ group }}
    - addusers:
      - {{ username }}
    - require:
      - user: {{ username }}_user
{%- endfor %}

{%- endfor %}
