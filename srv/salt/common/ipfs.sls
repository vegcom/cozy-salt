{%- set is_windows = grains['os_family'] == 'Windows' %}
{%- set mine_keys = salt['mine.get']('*', 'ipfs_private_swarm_key') %}

{%- set kubo_env = {
    "IPFS_PATH": "/opt/cozy/etc/kubo",
    "IPFS_LOGGING": "info",
    "IPFS_LOGGING_FMT": "json"
} %}

{%- if not is_windows %}
  {%- set current_path = salt['environ.get']('PATH') %}
  {%- do kubo_env.update({"PATH": "/opt/kubo/:" ~ current_path}) %}
{%- endif %}

{%- set ipfs_requires = [] %}
{%- for key, value in kubo_env.items() %}
  {%- do ipfs_requires.append({'environ': 'kubo_env_' ~ key | lower}) %}
{%- endfor %}

{%- for key, value in kubo_env.items() %}
kubo_env_{{ key | lower }}:
  environ.setenv:
    - name: {{ key }}
    - value: {{ value }}
    - update_minion: True
  {%- if is_windows %}
    - permanent: HKLM
  {%- endif %}
{%- endfor %}

ipfs_init:
  cmd.run:
    - name: ipfs init
    - env: {{ kubo_env | json }}
{%- if is_windows %}
    - unless: Test-Path "/opt/cozy/etc/kubo/config" -PathType Leaf
    - shell: pwsh
{%- else %}
    - unless: test -f /opt/cozy/etc/kubo/config
{%- endif %}
    - require: {{ ipfs_requires | json }}

ipfs_configure_private_networking:
  cmd.run:
    - names:
      - ipfs bootstrap rm --all
      - ipfs config Addresses.Swarm --json '["/ip4/10.0.0.0/ipcidr/16/tcp/4001", "/ip4/100.64.0.0/ipcidr/10/tcp/4001"]'
      - ipfs config Addresses.API "/ip4/100.64.0.0/ipcidr/10/tcp/5001"
      - ipfs config Addresses.Gateway "/ip4/100.64.0.0/ipcidr/10/tcp/8080"
      - ipfs config --json Swarm.AddrFilters '[]'
      - ipfs config Routing.Type dhtclient
      - ipfs config --json Discovery.MDNS.Enabled false
      - ipfs config --json Swarm.DisableNatPortMap true
      - ipfs config --json AutoConf.Enabled false
    - env: {{ kubo_env | json }}

ipfs_config_path:
  file.directory:
    - name: /opt/cozy/etc/kubo
    - mkdirs: True
{%- if is_windows %}
    - win_owner: 'Administrators'
    - win_perms:
        cozyusers:
          perms: full_control
{%- else %}
    - user: cozy-salt-svc
    - group: cozyusers
    - mode: '0770'
    - file_mode: '0660'
    - dir_mode: '0770'
    - recurse:
      - user
      - group
      - mode
{%- endif %}

ipfs_swarm_key:
  file.managed:
{%- if is_windows %}
    - name: C:/opt/cozy/etc/kubo/swarm.key
{%- else %}
    - name: /opt/cozy/etc/kubo/swarm.key
{%- endif %}
{%- if mine_keys %}
    - contents: |
        {{ mine_keys.values() | first | indent(8) }}
{%- else %}
    - source:  salt://_templates/swarm.key.jinja
    - template: jinja
{%- endif %}
    - replace: False
{%- if not is_windows %}
    - user: cozy-salt-svc
    - group: cozyusers
    - mode: '0660'
{%- endif %}
    - require:
      - cmd: ipfs_init
      - file: ipfs_config_path

share_swarm_key_to_mine:
  module.run:
    - mine.send:
      - name: ipfs_private_swarm_key
      - mine_function: file.read
      - path: /opt/cozy/etc/kubo/swarm.key
