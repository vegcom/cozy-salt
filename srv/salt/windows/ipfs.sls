{#- docs: https://ipfs.tech #}
{%- set _pinned = salt['pillar.get']('versions:kubo:version', '') %}
{%- set kubo_version = _pinned or salt['github_release.latest']('ipfs/kubo', fallback='v0.42.0', prerelease=True) %}
{%- set kubo_path = 'C:/opt/kubo' %}
{%- set kubo_source = "https://github.com/ipfs/kubo/releases/download/" ~ kubo_version ~ "/kubo_" ~ kubo_version ~ "_windows-amd64.zip" %}
{%- set kubo_hash = "https://github.com/ipfs/kubo/releases/download/" ~ kubo_version ~ "/kubo_" ~ kubo_version ~ "_windows-amd64.zip.sha512" %}

include:
  - common.ipfs
  - windows.paths

kubo_extract:
  archive.extracted:
    - name: {{ salt['file.dirname'](kubo_path) }}
    - source: {{ kubo_source }}
    - source_hash: {{ kubo_hash }}
