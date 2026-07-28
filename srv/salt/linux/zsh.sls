{%- from "_macros/git-repo.sls" import git_repo %}

{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}

{%- set omzsh_env = {
    "CHSH": "no",
    "KEEP_ZSHRC": "yes",
    "OVERWRITE_CONFIRMATION": "no",
    "ZSH_CUSTOM": "/opt/cozy/etc/oh-my-zsh/custom",
    "ZSH": "/opt/cozy/etc/oh-my-zsh",
    "RUNZSH":"no"
} %}

install_oh_my_zsh:
  cmd.script:
    - name: /tmp/oh-my-zsh_install.sh
    - source: https://github.com/ohmyzsh/ohmyzsh/raw/master/tools/install.sh
    - env: {{ omzsh_env | json }}
    - cwd: /
    - runas: {{ svc_name }}
    - unles: test -d $ZSH

{{ git_repo('zsh-autocomplete', '/opt/cozy/etc/oh-my-zsh/custom/plugins/zsh-autocomplete', svc_name, org='marlonrichert', state_id='marlonrichert/zsh-autocomplete') }}
