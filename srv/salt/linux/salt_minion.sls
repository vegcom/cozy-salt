{%- from '_macros/paths.sls' import managed_tree with context %}
{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set is_ci = salt['pillar.get']('SALT_CI', False) %}

{%- if not is_container or not is_ci %}
{{ managed_tree(
  '/etc/systemd/system/salt-minion.d',
  'salt://linux/files/etc-systemd-system-salt-minion.d',
  recurse=True, clean=True,
  user='root', group='root'
) }}
{%- endif %}

include:
  - common.salt_minion
