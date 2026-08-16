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

{%- set _yay_config = {} %}

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
  file.managed:
    - name: {{ dotfiles.dotfile_path(user_home, '.config/yay/init.lua') }}
    - contents: |-
        -- Managed by Salt - DO NOT EDIT MANUALLY
        -- Example init.lua: https://github.com/Jguer/yay/blob/next/doc/init.lua
        -- Online Manu: https://jguer.github.io/yay/man.html

        yay.opt.batch_install = true
        yay.opt.combined_upgrade = true
        yay.opt.double_confirm = false
        yay.opt.editor = "vim"
        yay.opt.editor_flags = "-u /dev/null"
        yay.opt.git_flags = "-c core.hooksPath=/dev/null -c init.templateDir=/dev/null -c include.path=/dev/null -c core.attributesfile=/dev/null -c core.excludesfile=/dev/null"
        yay.opt.keep_src = true
        yay.opt.max_concurrent_downloads = 0
        yay.opt.rebuild = "tree"
        yay.opt.redownload = "all"
        yay.opt.remove_make = "no"
        yay.opt.rpc = false
        yay.opt.single_line_results = true
        yay.opt.sort_by = "popularity"
        yay.opt.sudo_loop = true
        yay.opt.use_ask = true

{%- endfor %}
