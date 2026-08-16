{%- from '_macros/paths.sls' import managed_tree with context %}

{{ managed_tree(
  '/etc/systemd/system/salt-minion.d',
  'salt://linux/files/etc-systemd-system-salt-minion.d',
  recurse=True, clean=True,
  user='root', group='root'
) }}

include:
  - common.salt_minion
