{%- from '_macros/dotfiles.sls' import get_user_home %}
{%- set users = salt['pillar.get']('users', {}) %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- set is_windows = grains['os'] == 'Windows' %}

{%- if not is_windows %}
  {%- set usernames = managed_users %}
{%- else %}
  {%- from '_macros/windows.sls' import get_users_with_profiles with context %}
  {%- set usernames = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{%- endif %}

{%- for username in usernames %}
  {%- set base_username = username | replace('.' ~ grains['id'], '') %}
  {%- set userdata = users.get(base_username, {}) %}
  {%- if userdata.get('ssh_keys') %}
    {%- set user_home = get_user_home(username) | trim %}
    {%- set ssh_dir = user_home ~ '/.ssh' %}

# Ensure .ssh directory exists
{{ username }}_ssh_dir:
  file.directory:
    - name: {{ ssh_dir }}
    - user: {{ base_username }}
  {%- if grains['os'] != 'Windows' %}
    - group: {{ username }}
    - mode: "0700"
  {%- endif %}
    - makedirs: True

# Deploy authorized_keys
  {%- if grains['os'] == 'Windows' %}
    {%- set win_groups = userdata.get('windows_groups', []) %}
    {%- if 'Administrators' in win_groups %}
      {%- set auth_keys_path = 'C:/ProgramData/ssh/administrators_authorized_keys' %}
    {%- else %}
      {%- set auth_keys_path = ssh_dir ~ '/authorized_keys' %}
    {%- endif %}
{{ username }}_authorized_keys:
  file.managed:
    - name: {{ auth_keys_path }}
    - contents: |
        {{ userdata.ssh_keys | join('\n        ') }}
    - makedirs: True
    - require:
      - file: {{ username }}_ssh_dir

    {%- if 'Administrators' in win_groups %}
{{ username }}_authorized_keys_acl:
  cmd.run:
    - name: >-
        icacls "{{ auth_keys_path }}"
        /inheritance:r
        /grant "SYSTEM:(F)"
        /grant "Administrators:(F)"
        /q
    - shell: powershell
    - onchanges:
      - file: {{ username }}_authorized_keys
    {%- endif %}
  {%- else %}
    {%- for key in userdata.ssh_keys %}
{{ username }}_ssh_key_{{ loop.index }}:
  ssh_auth.present:
    - user: {{ username }}
    - name: {{ key }}
    - require:
      - file: {{ username }}_ssh_dir
    {%- endfor %}
  {%- endif %}
  {%- endif %}
{%- endfor %}
