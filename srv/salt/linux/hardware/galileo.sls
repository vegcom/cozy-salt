# Steam Deck (Valve Galileo/Jupiter) hardware tuning
# Only targeted via top.sls compound match on manufacturer/productname grains

etc-systemd-logind.conf.d_path:
  file.directory:
    - name: /etc/systemd/logind.conf.d
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-logind.conf.d:
  file.recurse:
    - name: /etc/systemd/logind.conf.d
    - source: salt://linux/files/etc-systemd-logind.conf.d
    - include_empty: True
    - clean: True
    - user: root
    - group: root
    - dir_mode: "0755"
    - file_mode: "0644"
    - require:
      - file: etc-systemd-logind.conf.d_path

logind_reload:
  service.running:
    - name: systemd-logind
    - onchanges:
      - file: etc-systemd-logind.conf.d

{%- set users = salt['pillar.get']('users', {}) %}
{%- for username, userdata in users.items() %}
  {%- if userdata.get('uid') %}
    {%- set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}

scopebuddy_config_{{ username }}:
  file.managed:
    - name: {{ user_home }}/.config/scopebuddy/scb.conf
    - source: salt://_templates/scopebuddy_config.jinja
    - template: jinja
    - makedirs: True
    - user_home: {{ user_home }}

  {%- endif %}
{%- endfor %}
