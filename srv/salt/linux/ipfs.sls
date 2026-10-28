{#- docs: https://ipfs.tech #}
{%- set _pinned = salt['pillar.get']('versions:kubo:version', '') %}
{%- set kubo_version = _pinned or salt['github_release.latest']('ipfs/kubo', fallback='v0.40.0', prerelease=True) %}
{%- set kubo_assets = salt['github_release.assets']('ipfs/kubo', tag=kubo_version, prerelease=True) %}
{%- set _kubo_candidates = [] %}
{%- for a in kubo_assets %}
  {%- if 'linux' in a.name|lower and not a.name.endswith('.cid') and not a.name.endswith('.sha512') %}
    {%- do _kubo_candidates.append(a) %}
  {%- endif %}
{%- endfor %}
{%- set kubo_patterns = salt['arch_match.patterns_for'](os_family='linux') %}
{%- set _kubo_asset = salt['arch_match.pick'](_kubo_candidates, kubo_patterns, key='name') %}
{%- set kubo_source = _kubo_asset.browser_download_url if _kubo_asset else none %}
{%- set kubo_hash = kubo_source ~ ".sha512" if kubo_source else none %}
{%- set kubo_path = '/opt/kubo' %}

{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                       salt['file.file_exists']('/run/.containerenv') -%}

{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{%- if is_container or is_ci %}

kubo_ipfs:
  test.nop:
    - name: "not deploying ipfs"

{%- else %}

include:
  - common.ipfs
  - linux.config

kubo_extract:
  archive.extracted:
    - name: {{ salt['file.dirname'](kubo_path) }}
    - source: {{ kubo_source }}
    - source_hash: {{ kubo_hash }}
    - skip_verify: False
    - user: cozy-salt-svc
    - group: cozyusers
    - mode: '0660'

{%- endif %}
