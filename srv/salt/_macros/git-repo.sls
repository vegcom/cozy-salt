# Git repo clone macro with token-authenticated URLs
# Usage: from "_macros/git-repo.sls" import git_repo
#        git_repo('cozy-presence', '/opt/cozy/cozy-presence', 'vegcom')

{%- macro git_repo(repo, target, user, branch='main', force_clone=False, force_reset=False, org='vegcom', state_id=None, require_file=None) -%}
{%- set token = salt['github_release.find_valid_token']() -%}
{%- set sid = state_id or repo | replace('.', '_') | replace('-', '_') ~ '_repo' -%}
{%- if token %}
{{ sid }}:
  git.latest:
    - name: https://{{ token }}@github.com/{{ org }}/{{ repo }}.git
    - target: {{ target }}
    - branch: {{ branch }}
{%- if grains['os'] != 'Windows' %}
    - user: {{ user }}
{%- endif %}
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
{%- else %}
{{ sid }}:
  test.nop:
    - name: Skipping {{ repo }} clone — no github token in pillar
{%- endif %}
{%- endmacro -%}
