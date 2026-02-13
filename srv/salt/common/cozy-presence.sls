# cozy-presence: Local identity persistence service

# Clone cozy-presence repo
cozy-presence-repo:
  git.latest:
    - name: https://github.com/hanna-brodie/cozy-presence.git
    - target: /opt/cozy-presence
    - branch: main
    - user: root

# Install dependencies (conda env should already be created)
cozy-presence-deps:
  cmd.run:
    - name: |
        source /opt/miniconda/bin/activate cozy-presence && \
        pip install typer rich --quiet
    - require:
      - git: cozy-presence-repo

# Create data directory
cozy-presence-data-dir:
  file.directory:
    - name: /home/{{ pillar.get('users', {}).get(managed_users[0], {}).get('name', 'vegcom') }}/.presence
    - user: {{ pillar.get('users', {}).get(managed_users[0], {}).get('name', 'vegcom') }}
    - group: {{ pillar.get('users', {}).get(managed_users[0], {}).get('name', 'vegcom') }}
    - mode: 700
    - makedirs: True

# Install CLI wrapper
cozy-presence-cli:
  file.managed:
    - name: /opt/cozy/bin/presence
    - source: salt://common/files/opt-cozy/bin/presence
    - mode: 755
    - require:
      - git: cozy-presence-repo

# Install systemd service
cozy-presence-service-file:
  file.managed:
    - name: /etc/systemd/system/cozy-presence.service
    - source: salt://common/services/cozy-presence.service
    - template: jinja
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
      - git: cozy-presence-repo