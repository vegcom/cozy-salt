# User-level environment.d management
# Deploys ~/.config/environment.d/*.conf for systemd user sessions
# Pillar: users:{username}:environment_d:{filename}: {VAR: value, ...}

{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{% for username in managed_users %}
{% set userdata = users.get(username, {}) %}
{% set env_files = userdata.get('environment_d', {}) %}
{% set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
{% set env_dir = user_home ~ '/.config/environment.d' %}

{% if env_files %}
# Ensure environment.d directory exists
{{ username }}_environment_d_dir:
  file.directory:
    - name: {{ env_dir }}
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0755"
    - makedirs: True

{% for filename, vars in env_files.items() %}
{{ username }}_env_{{ filename | replace('.', '_') }}:
  file.managed:
    - name: {{ env_dir }}/{{ filename }}.conf
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0644"
    - contents: |
        # Managed by Salt - {{ filename }}
{% for key, value in vars.items() %}
        {{ key }}={{ value }}
{% endfor %}
    - require:
      - file: {{ username }}_environment_d_dir
{% endfor %}
{% endif %}
{% endfor %}
