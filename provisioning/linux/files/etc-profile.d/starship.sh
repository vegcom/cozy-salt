#/etc/profile.d/starship.sh
# Managed by Salt - DO NOT EDIT MANUALLY
if ! which starship &>/dev/null ; then
    sh <(curl -sS https://starship.rs/install.sh) --force
fi

if [[ ! -f $HOME/.config/starship.toml ]]; then
    # Use custom theme if configured via Salt pillar, otherwise use Starship defaults
    mkdir -p $HOME/.config

{% set theme_url = salt['pillar.get']('shell:theme_url', '') -%}
{% if theme_url %}
    # Custom theme configured in pillar
    wget -O ~/.config/starship.toml "{{ theme_url }}" || {
        echo "Warning: Failed to download custom starship theme from {{ theme_url }}, using defaults"
    }
{% else %}
    # No custom theme configured, Starship will use its built-in defaults
    true
{% endif %}
fi

eval "$(starship init bash)"