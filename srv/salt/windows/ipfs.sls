{#- docs: https://ipfs.tech #}
{%- set _pinned = salt['pillar.get']('versions:kubo:version', '') %}
{%- set kubo_version = _pinned or salt['github_release.latest']('ipfs/kubo', fallback='v0.42.0', prerelease=True) %}
{%- set kubo_path = 'C:/opt/kubo' %}
{%- set arch = salt['grains.get']('osarch') %}
{%- set kubo_source = "https://github.com/ipfs/kubo/releases/download/" ~ kubo_version ~ "/kubo_" ~ kubo_version ~ "_windows-" ~ arch ~ ".zip" %}
{%- set kubo_hash = kubo_source ~ ".sha512" %}

{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{%- if is_ci %}

kubo_ipfs:
  test.nop:
    - name: "not deploying ipfs"

{%- else %}

include:
  - common.ipfs
  - windows.paths

kubo_extract:
  archive.extracted:
    - name: {{ salt['file.dirname'](kubo_path) }}
    - source: {{ kubo_source }}
    - source_hash: {{ kubo_hash }}

{%- endif %}
