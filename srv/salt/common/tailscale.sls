# tailscale configuration
# Connects tailscale to headscale login server using pillar-provided auth key
# Pillar structure:
# {# example in srv/pillar/secrets/init.sls.example #}
#   headscale:
#     auth-key: "hskey-auth-..."
#     login-server: "https://headscale.example.com"

{% set headscale = salt['pillar.get']('headscale', {}) %}
{% set auth_key = headscale.get('auth-key', '') %}
{% set login_server = headscale.get('login-server', '') %}

{% if auth_key and login_server %}
tailscale_up:
  cmd.run:
    - name: tailscale up --login-server {{ login_server }} --authkey {{ auth_key }}
    - unless: tailscale status
{% else %}
tailscale_up_skipped:
  test.noop:
    - name: headscale pillar not configured, skipping tailscale up
{% endif %}
