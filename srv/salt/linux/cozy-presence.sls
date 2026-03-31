# cozy-presence: Local identity persistence service
{% from "_macros/git-repo.sls" import git_repo %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set run_user = managed_users[0] if managed_users else '' -%}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                       salt['file.file_exists']('/run/.containerenv') -%}
{%- set token = salt['pillar.get']('github:tokens', [''])[0] -%}
{%- set cozy_presence_path = "/opt/cozy/cozy-presence" %}
{%- set cozy_presence_env = "/opt/miniforge3/envs/cozy-presence" %}
{%- set embedding_url = salt['pillar.get']('services:embedding:langcache:url', '') -%}
{%- set embedding_dim = salt['pillar.get']('services:embedding:langcache:dim', '') -%}
{%- set cozy_presence_cfg = "/opt/cozy/etc/cozy-presence.conf" %}
{%- set cozy_presence_bin = cozy_presence_env + "/bin" %}

{%- if run_user and not is_container and token %}
# Create /opt/cozy/ with correct ownership (always enforced, no creates guard)
cozy_presence_repo_dir:
  file.directory:
    - name: /opt/cozy/
    - user: {{ run_user }}
    - group: cozyusers
    - mode: "0770"
    - makedirs: True

# Clone cozy-presence repo (token from pillar)
{{ git_repo('cozy-presence', cozy_presence_path, run_user, state_id='cozy_presence_repo' ,require_file='cozy_presence_repo_dir') }}

# Setup conda env
cozy_presence_env_create:
  cmd.run:
    - name: |
        /opt/miniforge3/bin/mamba env create -f {{ cozy_presence_path }}/environment.yml
    - user: {{ run_user }}
    - require:
      - git: cozy_presence_repo
    - unless: test -d /opt/miniforge3/envs/cozy-presence/

# Update conda env
cozy_presence_env_update:
  cmd.run:
    - name: |
        /opt/miniforge3/bin/mamba env update -f {{ cozy_presence_path }}/environment.yml --prune
    - user: {{ run_user }}
    - onchanges:
      - git: cozy_presence_repo


# Install in conda env
cozy_presence_pip:
  cmd.run:
    - name: |
        {{ cozy_presence_bin }}/pip install -e {{ cozy_presence_path }}
    - user: {{ run_user }}
    - onchanges:
      - cmd: cozy_presence_env_update
    - require:
      - git: cozy_presence_repo

# Install CLI wrapper
cozy_presence_cli:
  file.managed:
    - name: /opt/cozy/bin/presence
    - source: salt://common/files/opt-cozy-bin/presence
    - mode: "0755"
    - require:
      - git: cozy_presence_repo

# Install systemd service template
cozy_presence_service_file:
  file.managed:
    - name: /etc/systemd/user/cozy-presence@.service
    - source: salt://linux/files/etc-systemd-user/cozy-presence@.service
    - mode: "0644"

cozy_presence_config:
  file.managed:
    - name: {{ cozy_presence_cfg }}
    - contents: |
        PRESENCE_EMBED_URL={{ embedding_url }}
        PRESENCE_EMBED_DIM={{ embedding_dim }}
    - require:
      - file: cozy_presence_service_file

# Per-user: data dir + service enable
{% for username in managed_users %}
{%- set user_info = salt['user.info'](username) %}
{%- if user_info %}

cozy_presence_data_dir_{{ username }}:
  file.directory:
    - name: {{ user_info['home'] }}/.presence
    - user: {{ username }}
    - group: {{ username }}
    - mode: "0700"
    - makedirs: True

cozy_presence_service_{{ username }}:
  cmd.run:
    - name: |
        systemd-run --quiet --machine={{ username }}@.host --user --collect --pipe --wait \
            sh -c 'systemctl --user enable --now cozy-presence@{{ username }}.service'
    - require:
      - file: cozy_presence_config
      - file: cozy_presence_service_file
      - file: cozy_presence_data_dir_{{ username }}
    - watch:
      - git: cozy_presence_repo

{%- endif %}
{% endfor %}

{%- else %}

cozy_presence_noop:
  test.nop:
    - name: Cozy Presence requires a user account and systemd (skipped in containers)

{%- endif %}
