{% from "_macros/git-repo.sls" import git_repo %}
{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) -%}
{%- set run_user = managed_users[0] if managed_users else '' -%}
{%- set run_user_info = salt['user.info'](run_user) if run_user else {} -%}
{%- set cozy_path = 'C:\\opt\\cozy\\' %}
{%- set cozy_fragments_path = cozy_path ~ 'cozy-fragments\\' %}
{%- set cozy_fragments_script = cozy_fragments_path ~ 'install.ps1' %}
{%- set twilite_theme_dir = 'C:\\ProgramData\\Microsoft\\Windows Terminal\\Fragments\\Twilite'%}
{%- set twilite_theme_install_uri = "https://raw.githubusercontent.com/vegcom/WindowsTerminal-Twilite/main/install.ps1" %}

{%- if run_user_info %}
cozy_fragments_repo_dir:
  file.directory:
    - name: '{{ cozy_path }}'
    - user: {{ run_user }}
    - group: cozyusers
    - mode: 770
    - makedirs: True

{{ git_repo('cozy-fragments', cozy_fragments_path, run_user, state_id='cozy_fragments_repo' ,require_file='cozy_fragments_repo_dir') }}

cozy_fragments_install:
  cmd.run:
    - name: pwsh -Command "& {{ cozy_fragments_script }}"
    - shell: pwsh
    - cwd: '{{ cozy_fragments_path }}'
    - onchanges:
      - git: cozy_fragments_repo
    - require:
      - file: cozy_fragments_repo_dir
      - git: cozy_fragments_repo
{%- else %}
cozy_fragments_noop:
  test.nop:
    - name: Cozy fragments requires a user account to run
{%- endif %}

twilite_theme_install:
  cmd.run:
    - name: pwsh -Command "iex ((New-Object System.Net.WebClient).DownloadString('{{ twilite_theme_install_uri }}'))"
    - shell: pwsh
    - env:
      - themeDir: {{ twilite_theme_dir }}
    - onchanges:
      - git: cozy_fragments_repo
    - require:
      - file: cozy_fragments_repo_dir
      - git: cozy_fragments_repo
