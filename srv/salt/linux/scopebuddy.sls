{%- set users = salt['pillar.get']('users', {}) %}
{%- for username, userdata in users.items() %}
  {%- if userdata.get('uid') %}
    {%- set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}

scopebuddy_scb_{{ username }}:
  file.managed:
    - name: {{ user_home }}/.config/scopebuddy/scb.conf
    - source: salt://_templates/scopebuddy_scb_config.jinja
    - template: jinja
    - makedirs: True
    - user_home: {{ user_home }}

scopebuddy_gamemode_{{ username }}:
  file.managed:
    - name: {{ user_home }}/.config/scopebuddy/gamemode.conf
    - source: salt://_templates/scopebuddy_gamemode_config.jinja
    - template: jinja
    - makedirs: True
    - user_home: {{ user_home }}

  {%- endif %}
{%- endfor %}
