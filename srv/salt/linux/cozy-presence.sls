# cozy-presence: Local identity persistence service
{% from "_macros/git-repo.sls" import git_repo %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set run_user = managed_users[0] if managed_users else '' -%}
{%- set run_user_info = salt['user.info'](run_user) if run_user else {} -%}
{%- set cozy_presence_path = "/opt/cozy/cozy-presence" %}
{%- set cozy_presence_env = "/opt/miniforge3/envs/cozy-presence" %}
{%- set cozy_presence_bin = cozy_presence_env + "/bin" %}

{%- if run_user_info %}
# Create data directory
cozy-presence-repo-dir:
  file.directory:
    - name: /opt/cozy/
    - user: {{ run_user }}
    - group: cozyusers
    - mode: 770
    - makedirs: True
    - creates: /opt/cozy/

# Clone cozy-presence repo (token from pillar)
{{ git_repo('cozy-presence', cozy_presence_path, run_user) }}

# Setup conda env
cozy_presence_env_create:
  cmd.run:
    - name: |
        /opt/miniforge3/bin/mamba env create -f {{ cozy_presence_path }}/environment.yml
    - creates:
      - {{ cozy_presence_env }}/lib/python3.12/venv/scripts/common/activate
    - require:
      - git: cozy_presence_repo

# Update conda env
cozy_presence_env_update:
  cmd.run:
    - name: |
        /opt/miniforge3/bin/mamba env update -f {{ cozy_presence_path }}/environment.yml --prune
    - require:
      - cmd: cozy_presence_env_create

# Install in conda env
cozy_presence_pip:
  cmd.run:
    - name: |
        {{ cozy_presence_bin }}/pip install -e {{ cozy_presence_path }}
    - require:
      - git: cozy_presence_repo
      - cmd: cozy_presence_env_create

# Create data directory
cozy_presence_data_dir:
  file.directory:
    - name: /home/{{ run_user }}/.presence
    - user: {{ run_user }}
    - group: {{ run_user }}
    - mode: 700
    - makedirs: True

# Install CLI wrapper
cozy_presence_cli:
  file.managed:
    - name: /opt/cozy/bin/presence
    - source: salt://common/files/opt-cozy-bin/presence
    - mode: 755
    - require:
      - git: cozy_presence_repo

# TODO: Managed in srv/salt/linux/config.sls
# Install systemd service
cozy_presence_service_file:
  file.managed:
    - name: /etc/systemd/user/cozy-presence@.service
    - source: salt://linux/files/etc-systemd-user/cozy-presence@.service
    - mode: 644

cozy_presence_service:
  cmd.run:
    - name: |
        systemctl --user daemon-reload
        systemctl --user enable --now cozy-presence@{{ run_user }}.service
    - runas: {{ run_user }}
    - env:
        XDG_RUNTIME_DIR: /run/user/{{ run_user_info['uid'] }}
    - require:
      - file: cozy_presence_service_file
      - file: cozy_presence_data_dir
    - watch:
      - git: cozy_presence_repo

{%- else %}

cozy_presence_noop:
  test.nop:
    - name: Cozy Presence requires a user account to run

{%- endif %}
