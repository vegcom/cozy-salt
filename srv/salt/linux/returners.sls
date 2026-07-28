{%- set conf_dir = salt['pillar.get']('config_paths:salt:linux', '/etc/salt') %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

returners:
  file.managed:
    - name: {{ conf_dir }}/minion.d/returners.conf
    - source: salt://_templates/returners.conf.jinja
    - template: jinja
    - mode: '0600'
    - makedirs: True

{%- if not is_container %}
salt_minion_returner_restart:
  service.running:
    - name: salt-minion
    - watch:
      - file: returners
{%- endif %}
