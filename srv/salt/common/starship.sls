# Starship prompt configuration
# Deploys Starship-Twilite theme to managed users
# Windows: handled via cozy-pwsh (https://github.com/vegcom/cozy-pwsh)

{% import '_macros/dotfiles.sls' as dotfiles %}

{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}

{% if grains['os_family'] != 'Windows' %}
{% for username in managed_users %}
{% set user_home = dotfiles.get_user_home(username) %}

starship_config_{{ username }}:
  cmd.run:
    - name: >
        curl -fsSL
        https://raw.githubusercontent.com/vegcom/Starship-Twilite/main/starship.toml
        -o {{ user_home }}/.config/starship.toml
    - creates: {{ user_home }}/.config/starship.toml
    - runas: {{ username }}

{% endfor %}
{% endif %}
