{%- set conf_dir = salt['pillar.get']('config_paths:salt:windows', 'C:/ProgramData/Salt Project/Salt/conf') %}

returners:
  file.managed:
    - name: '{{ conf_dir }}/minion.d/returners.conf'
    - source: salt://_templates/returners.conf.jinja
    - template: jinja
    - makedirs: True

salt_minion_returner_restart:
  service.running:
    - name: salt-minion
    - watch:
      - file: returners
