{#- TODO: pillar.get the configs.paths, don't waste time writing pillars, just have defaults as they are detailed below 💜 #}
# ============================================================================
# YAY Lua
#
# docs:
# - https://github.com/Jguer/yay/blob/next/doc/lua.md
# - https://luals.github.io/wiki/configuration/
#
# hooks:
# - https://github.com/Jguer/yay/raw/next/doc/examples/hide_first_submitted.lua
# - https://github.com/Jguer/yay/raw/next/doc/examples/install_log.lua
# - https://github.com/Jguer/yay/raw/next/doc/examples/maintainer_change.lua
# - https://github.com/Jguer/yay/raw/next/doc/examples/recently_modified.lua
# - https://github.com/Jguer/yay/raw/next/doc/examples/single_line.lua
# ============================================================================

{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}

{#- default: /usr/share/yay #}
{%- set _yay_dir = "/usr/share/yay" %}

{#- default: /usr/share/yay/meta #}
{%- set _yay_lua_dir = _yay_dir ~ "/meta" %}

{#- default: /usr/share/yay/meta/*.lua #}
{%- set _yay_lua_hooks = [
  "hide_first_submitted", "install_log", "single_line",
  "maintainer_change", "recently_modified"
] %}

{#- paths #}
{%- set _mkdirs = [_yay_dir, _yay_lua_dir] %}

# ============================================================================
# YAY lua workspace.library
# ============================================================================

{%- for dir in _mkdirs %}

yay_dir{{ dir | replace("/", "_") }}:
  file.directory:
    - name: {{ _yay_lua_dir }}
    - makedirs: True
    - mode: "0775"
    - user: {{ service_user }}
    - group: cozyusers
    - order: {{ loop.index }}
    - recurse:
      - user
      - group
      - mode

{%- endfor %}

# ============================================================================
# YAY lua-language-server
# ============================================================================

yay_lua_language_server:
  file.managed:
    - name: {{ _yay_lua_dir }}/yay.d.lua
    - source: https://github.com/Jguer/yay/raw/next/meta/yay.d.lua
    - skip_verify: True
    - makedirs: True
    - mode: "0664"
    - user: {{ service_user }}
    - group: cozyusers
    - require:
      - file: yay_dir_usr_share_yay
      - file: yay_dir_usr_share_yay_meta

# ============================================================================
# YAY lua hooks
# ============================================================================

{%- for hook in _yay_lua_hooks %}

yay_lua_hook_{{ hook }}:
  file.managed:
    - name: {{ _yay_lua_dir }}/{{ hook }}.lua
    - source: https://github.com/Jguer/yay/raw/next/doc/examples/{{ hook }}.lua
    - skip_verify: True
    - makedirs: True
    - mode: "0664"
    - user: {{ service_user }}
    - group: cozyusers
    - require:
      - file: yay_dir_usr_share_yay
      - file: yay_dir_usr_share_yay_meta

{%- endfor %}

# ============================================================================
# YAY luarc
# ============================================================================

{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- import '_macros/dotfiles.sls' as dotfiles %}

{#- default: $HOME/.config/yay/.luarc.json #}
{%- set _yay_luarc = {
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "runtime": {"version": "Lua 5.1"},
  "workspace": {"library": [ _yay_lua_dir ]}
} %}

{%- for username in managed_users %}
{%- set user_home = dotfiles.get_user_home(username) | trim %}

yay_luarc_{{ username }}:
  file.serialize:
    - name: {{ dotfiles.dotfile_path(user_home, '.config/yay/.luarc.json') }}
    - serializer: json
    - merge_if_exists: True
    - dataset: {{ _yay_luarc | tojson }}
    - user: {{ username }}
    - group: {{ username }}

{%- endfor %}
