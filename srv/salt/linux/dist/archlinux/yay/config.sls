# ============================================================================
# YAY CONFIG
# Runs as per managed_user
# ----------------------------------------------------------------------------
# docs:
#  - https://github.com/Jguer/yay/blob/next/doc/index.md
#  - https://github.com/Jguer/yay/blob/next/doc/lua.md
# lua-language-server:
#  - https://github.com/Jguer/yay/blob/next/meta/yay.d.lua
# ----------------------------------------------------------------------------
# - [ ] TODO: move from config.json to init.lua per best practices
#   - config.json is to only be edited via commandline evocation
# ============================================================================

{%- set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{%- import '_macros/dotfiles.sls' as dotfiles %}

{%- set _yay_config = {
  "gitflags": "-c core.hooksPath=/dev/null -c init.templateDir=/dev/null -c include.path=/dev/null -c commit.gpgsign=false -c tag.forceSignAnnotated=false",
  "rpc": true, "requestsplitn": 28,
  "completionrefreshtime": 3, "maxconcurrentdownloads": 0,
  "removemake": "no", "keepSrc": true,
  "redownload": "all", "batchinstall": true,
  "debug": true,
  "devel": false, "rebuild": "tree",
  "doubleconfirm": false,
  "answerclean": "", "answerdiff": "",
  "answeredit": "", "answerupgrade": "", "combinedupgrade": true,
  "useask": true, "sudoloop": true,
  "sortby": "popularity",
  "timeupdate": true,
} %}

{%- for username in managed_users %}
  {%- set user_home = dotfiles.get_user_home(username) | trim %}

yay_conf_dir_{{ username }}:
  file.directory:
    - name: {{ user_home ~ '/.config/yay' }}
    - makedirs: True
    - force: True
    - mode: "0750"
    - user: {{ username }}
    - group: {{ username }}

yay_conf_{{ username }}:
  file.serialize:
    - name: {{ dotfiles.dotfile_path(user_home, '.config/yay/config.json') }}
    - serializer: json
    - merge_if_exists: True
    - dataset: {{ _yay_config | tojson }}
    - user: {{ username }}
    - group: {{ username }}

{%- endfor %}
