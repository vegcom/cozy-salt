# WSL-specific /etc/wsl.conf management
# Must run BEFORE linux.config to prevent WSL from overwriting /etc/hosts and /etc/resolv.conf
# Configures: systemd enablement + DNS control

{%- set is_wsl = grains.get('kernelrelease', '').find('WSL') != -1 %}
{%- set host_name = grains.get('id') %}

{%- if is_wsl %}
wsl_config:
  file.managed:
    - name: /etc/wsl.conf
    - source: salt://_templates/wsl.conf.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True
    - host_name: {{ host_name }}
{%- else %}
wsl_config:
  test.nop:
    - name: Skipping wsl.conf - not running on WSL
{%- endif %}
