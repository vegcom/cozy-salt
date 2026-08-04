{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}
{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set ipfs_enabled = salt['pillar.get']('host:capabilities:ipfs', False) %}

{%- if is_container or is_ci or not ipfs_enabled %}
ipfs_skip:
  test.nop:
    - name: "no ipfs on this host"
{%- else %}
include:
{%- if is_windows %}
  - windows.ipfs
{%- else %}
  - linux.ipfs
{%- endif %}
  - common.ipfs.config
  - common.ipfs.mine

{#- Sync - Syncing is handled via reactor
            the following events result in syncing actions:

ipfs_sync_peers:
  event.send:
    - name: cozy/ipfs/peers

ipfs_sync_publish:
  event.send:
    - name: cozy/ipfs/publish

ipfs_sync_mfs:
  event.send:
    - name: cozy/ipfs/mfs
#}

{%- endif %}
