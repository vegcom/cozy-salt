# Included by tor
{%- set password = salt['pillar.get']('tor:mgmt', false) -%}
{%- if password -%}
shadowsocks_config:
  file.serialize:
    - name: 'C:/Program Files (x86)/WinGet/Packages/shadowsocks.shadowsocks-windows_Microsoft.Winget.Source_8wekyb3d8bbwe/gui-config.json'
    - serializer: json
    - merge_if_exists: True
    - dataset: {"configs":[{"server":"localhost","server_port":9050,"password":"{{ password }}","method":"chacha20-ietf-poly1305","timeout":30,"warnLegacyUrl":false}],"localPort":1080,"portableMode":true,"useOnlineac": false,"pacUrl": "http://127.0.0.1:1080/tor","generateLegacyUrl": true,}
{%- endif -%}
