# SSH Key Management (Cross-Platform)
# Deploys authorized_keys for managed users from pillar
# Works on Linux and Windows (OpenSSH)

{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{% for username in managed_users %}
{% set userdata = users.get(username, {}) %}
{% if userdata.get('ssh_keys') %}

{% if grains['os'] == 'Windows' %}
{% set user_home = 'C:\\Users\\' ~ username %}
{% set ssh_dir = user_home ~ '\\.ssh' %}
{% else %}
{% set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
{% set ssh_dir = user_home ~ '/.ssh' %}
{% endif %}

# Ensure .ssh directory exists
{{ username }}_ssh_dir:
  file.directory:
    - name: {{ ssh_dir }}
    - user: {{ username }}
{% if grains['os'] != 'Windows' %}
    - group: {{ username }}
    - mode: "0700"
{% endif %}
    - makedirs: True

# Deploy authorized_keys
{% for key in userdata.ssh_keys %}
{{ username }}_ssh_key_{{ loop.index }}:
  ssh_auth.present:
    - user: {{ username }}
    - name: {{ key }}
    - require:
      - file: {{ username }}_ssh_dir
{% endfor %}

{% endif %}
{% endfor %}
