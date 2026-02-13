# cozy-presence: Local identity persistence service
{% from "_macros/git-repo.sls" import git_repo %}
{%- set managed_users = salt['pillar.get']('managed_users', []) -%}
{%- set run_user = managed_users[0] -%}


# Create data directory
cozy-presence-repo-dir:
  file.directory:
    - name: /opt/cozy/
    - user: {{ run_user }}
    - group: cozyusers
    - mode: 770
    - makedirs: True

# Clone cozy-presence repo (token from pillar)
{{ git_repo('cozy-presence', '/opt/cozy/cozy-presence', run_user) }}

# Setup conda env
cozy-presence-env:
  cmd.run:
    - name: |
        /opt/miniforge3/bin/mamba env create -f /opt/cozy/cozy-presence/environment.yml
    - require:
      - git: cozy_presence_repo

# Install dependencies
cozy-presence-deps:
  cmd.run:
    - name: |
        source /bin/activate cozy-presence && \
        pip install typer rich --quiet
    - require:
      - git: cozy_presence_repo
      - cmd: cozy-presence-env

# Create data directory
cozy-presence-data-dir:
  file.directory:
    - name: /home/{{ run_user }}/.presence
    - user: {{ run_user }}
    - group: {{ run_user }}
    - mode: 700
    - makedirs: True

# Install CLI wrapper
cozy-presence-cli:
  file.managed:
    - name: /opt/cozy/bin/presence
    - source: salt://common/files/opt-cozy/bin/presence
    - mode: 755
    - require:
      - git: cozy_presence_repo

# Install systemd service
cozy-presence-service-file:
  file.managed:
    - name: /etc/systemd/system/cozy-presence.service
    - source: salt://common/services/cozy-presence.service
    - template: jinja
    - context:
        run_user: {{ run_user }}
    - mode: 644

# Enable and start service
cozy-presence-service:
  service.running:
    - name: cozy-presence
    - enable: True
    - require:
      - file: cozy-presence-service-file
      - cmd: cozy-presence-deps
      - file: cozy-presence-data-dir
    - watch:
      - git: cozy_presence_repo
