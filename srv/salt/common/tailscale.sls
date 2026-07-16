# tailscale configuration
# Connects tailscale to headscale login server using pillar-provided auth key
# Pillar structure: srv/pillar/secrets/README.md
#   headscale:
#     auth-key: "hskey-auth-..."
#     login-server: "https://headscale.example.com"
#   tailscale:
#     flags:            # merged: common pillar sets defaults, host pillar overrides
#       advertise-exit-node: True
#       advertise-routes: "10.0.0.0/24"

{%- set enabled = salt['pillar.get']('host:capabilities:tailscale', True) %}
{%- set headscale = salt['pillar.get']('headscale', {}) %}
{%- set auth_key = headscale.get('auth-key', '') %}
{%- set login_server = headscale.get('login-server', '') %}

{%- if enabled and auth_key and login_server %}

{%- set ts_flags = salt['pillar.get']('tailscale:flags', {}) %}
{%- set flag_parts = [] %}
{%- for k, v in ts_flags.items() %}
  {%- if v is sameas true %}
    {%- do flag_parts.append('--' ~ k) %}
  {%- elif v is sameas false %}
    {%- do flag_parts.append('--' ~ k ~ '=false') %}
  {%- else %}
    {%- do flag_parts.append('--' ~ k ~ '=' ~ v) %}
  {%- endif %}
{%- endfor %}

tailscale_up:
  cmd.run:
    - name: tailscale up --force-reauth --reset --report-posture --login-server {{ login_server }} --auth-key {{ auth_key }}
    - unless: tailscale ip

  {%- if flag_parts %}
tailscale_set:
  cmd.run:
    - name: tailscale set {{ flag_parts | join(' ') }}
    - onlyif: tailscale status
    - require:
      - cmd: tailscale_up
{%- endif %}

{%- else %}
tailscale_up_skipped:
  test.nop:
    - name: >-
        tailscale skipped —
        {%- if not enabled %}disabled via host:capabilities:tailscale
        {%- else %}headscale pillar not configured{%- endif %}
{%- endif %}
