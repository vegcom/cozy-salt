# Steam Deck (Valve Galileo/Jupiter) hardware tuning
# Only targeted via top.sls compound match on manufacturer/productname grains

{#- systemd #}
etc-systemd_path:
  file.directory:
    - name: /etc/systemd
    - user: root
    - group: root
    - mode: "0755"

{#- systemd - zram #}
etc-systemd-zram-generator.conf:
  file.managed:
    - name: /etc/systemd/zram-generator.conf
    - source: salt://linux/files/etc-systemd/zram-generator.conf
    - template: jinja
    - makedirs: True
    - require:
      - file: etc-systemd_path

{#- systemd - sleep.conf #}
etc-systemd-sleep.conf.d_path:
  file.directory:
    - name: /etc/systemd/sleep.conf.d
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-sleep.conf.d-cozy-galileo.conf:
  file.managed:
    - name: /etc/systemd/sleep.conf.d/cozy.conf
    - source: salt://linux/files/etc-systemd-sleep.conf.d/cozy-galileo.conf
    - template: jinja
    - makedirs: True
    - require:
      - file: etc-systemd-sleep.conf.d_path

{#- systemd - login.d #}
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

{#- mkinitcpio #}
etc-mkinitcpio.d_path:
  file.directory:
    - name: /etc/mkinitcpio.d
    - user: root
    - group: root
    - mode: "0755"

etc-mkinitcpio.d-linux.conf:
  file.managed:
    - name: /etc/mkinitcpio.d/linux.conf
    - source: salt://linux/files/etc-mkinitcpio.d/cozy-galileo.conf
    - template: jinja
    - makedirs: True
    - require:
      - file: etc-mkinitcpio.d_path

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
