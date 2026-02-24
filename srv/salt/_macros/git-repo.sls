# Git repo clone macro with token-authenticated URLs
# Usage: from "_macros/git-repo.sls" import git_repo
#        git_repo('cozy-presence', '/opt/cozy/cozy-presence', 'vegcom')

{%- macro git_repo(repo, target, user, branch='main', force_clone=False, force_reset=False, org='vegcom', state_id=None, require_file=None) -%}
{%- set token = salt['pillar.get']('github:tokens', [''])[0] -%}
{%- set sid = state_id or repo | replace('.', '_') | replace('-', '_') ~ '_repo' -%}
{{ sid }}:
  git.latest:
    - name: https://{{ token }}@github.com/{{ org }}/{{ repo }}.git
    - target: {{ target }}
    - branch: {{ branch }}
    - user: {{ user }}
{%- if force_clone %}
    - force_clone: True
{%- endif %}
{%- if force_reset %}
    - force_reset: True
{%- else %}
    - force_reset: remote-changes
{%- endif %}
{%- if require_file %}
    - require:
      - file: {{ require_file }}
{%- endif %}
{%- endmacro -%}
