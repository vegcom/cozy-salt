{%- set os_key = 'windows' if grains['os_family'] == 'Windows' else 'linux' %}
{%- set mongo_host = salt['pillar.get']('mongo.host', '') %}
{%- set mongo_pass = salt['pillar.get']('mongo.password', '') %}
{%- if os_key == 'windows' and (mongo_host and mongo_pass) %}
  {%- set install_dir = salt['pillar.get']('install_paths:salt:' ~ os_key, 'C:\Program Files\Salt Project\Salt') %}
  {%- set conf_dir = salt['pillar.get']('config_paths:salt:' ~ os_key, ' C:\salt\conf') %}
pymongo_for_returner:
  cmd.run:
    - name: '"{{ install_dir }}\Scripts\pip3" install pymongo'
    - unless: '"{{ install_dir }}\Scripts\python3" -c "import pymongo"'
mongo_returner:
  file.managed:
    - name: '{{ conf_dir }}\minion.d\mongo-returner.conf'
    - makedirs: True
    - contents: |
        mongo.host: {{ mongo_host }}
        mongo.port: {{ salt['pillar.get']('mongo.port', 27017) }}
        mongo.db: {{ salt['pillar.get']('mongo.db', 'salt') }}
        mongo.user: {{ salt['pillar.get']('mongo.user', 'salt') }}
        mongo.password: {{ mongo_pass }}
        mongo.authdb: {{ salt['pillar.get']('mongo.authdb', 'admin') }}
        return: mongo
salt_minion_returner_restart:
  service.running:
    - name: salt-minion
    - watch:
      - file: mongo_returner
{%- endif %}
