{%- from '_macros/paths.sls' import managed_tree with context %}

{%- set cozy_etc = salt['pillar.get']('config_paths:cozy:linux') %}
{%- set cozy_profile = salt['pillar.get']('config_paths:cozy_profile:linux') %}
{%- set cozy_environment = salt['pillar.get']('config_paths:cozy_environment:linux') %}
{%- set cozy_bin = salt['pillar.get']('install_paths:cozy:linux') %}
{#- /etc #}
{{ managed_tree('/etc',
                'salt://linux/files/etc/',
                user='root', group='root',
                dir_mode='0755', file_mode='0644',
                recurse=True, clean=False,) }}

{{ managed_tree('/etc/systemd/system',
                'salt://linux/files/etc-systemd-system',
                recurse=True, clean=False,
                user='root', group='root') }}

{{ managed_tree('/etc/systemd/user',
                'salt://linux/files/etc-systemd-user',
                recurse=True, clean=False,
                user='root', group='root') }}

{{ managed_tree('/etc/environment.d',
                'salt://linux/files/etc-environment.d',
                recurse=True, clean=False,
                user='root', group='root') }}

{{ managed_tree('/etc/profile.d',
                'salt://linux/files/etc-profile.d/',
                recurse=True, clean=False,
                user='root', group='root') }}

{{ managed_tree('/etc/zsh',
                'salt://linux/files/etc-zsh/',
                recurse=True, clean=True,
                user='root', group='root',) }}

{#- /opt/cozy #}
{{ managed_tree('/opt/cozy',
                'salt://linux/files/opt-cozy',
                user='cozy-salt-svc', group='cozyusers',
                recurse=False, clean=False,
                dir_mode='0775', file_mode='0775') }}

{{ managed_tree(cozy_etc,
                'salt://linux/files/opt-cozy-etc',
                user='cozy-salt-svc', group='cozyusers',
                recurse=False, clean=False,
                dir_mode='0775', file_mode='0775') }}

{{ managed_tree(cozy_bin,
                'salt://linux/files/opt-cozy-bin',
                user='cozy-salt-svc', group='cozyusers',
                recurse=True, clean=True,
                dir_mode='0775', file_mode='0775') }}

{{ managed_tree(cozy_profile,
                'salt://linux/files/opt-cozy-etc-profile.d',
                user='root', group='cozyusers',
                recurse=True, clean=True,
                dir_mode='0775', file_mode='0665') }}

{{ managed_tree(cozy_environment,
                'salt://linux/files/opt-cozy-etc-environment.d',
                user='cozy-salt-svc', group='cozyusers',
                recurse=True, clean=True,
                dir_mode='0775', file_mode='0665') }}

include:
  - .banners
