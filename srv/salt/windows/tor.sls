# [ ] TODO: in places we do `config_paths:torrc:windows` we can solve for OS
#       and omit hard-codin would be a nice way to remove/limit reuse
# [ ] TODO: move tor_config to common, leave OS particulars per; or wrap in macro

{%- set torrc = salt['pillar.get']('config_paths:tor:windows', "c:/opt/cozy/etc/torrc") %}
{%- set torrcd = salt['pillar.get']('config_paths:tord:windows', "c:/opt/cozy/etc/torrc.d") %}
{%- set password = salt['pillar.get']('tor:mgmt', false) %}
{%- if password %}
  {%- set _cmd = "tor -f " ~ torrc ~ " --quiet --hash-password " ~ password if password %}
  {%- set hashed = salt['cmd.run'](_cmd) %}
{%- endif %}
tor_config:
  file.managed:
    - name: {{ torrc }}
    - source: salt://windows/files/opt-cozy-etc/torrc
    - makedirs: True
{%- if hashed %}
tor_auth:
  file.managed:
    - name: {{ torrcd }}/mgmt
    - contents: HashedControlPassword {{ hashed }}
{%- else %}
tor_auth_skipped:
  - name: missing `tor:mgmt` pillar
{%- endif %}
tor_log_path:
  file.directory:
    - name: c:/opt/cozy/logs/
    - makedirs: True
    - clean: False

include:
  - .shadowsocks
