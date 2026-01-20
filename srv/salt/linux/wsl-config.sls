# WSL-specific /etc/wsl.conf management
# Must run BEFORE linux.config to prevent WSL from overwriting /etc/hosts and /etc/resolv.conf
# Configures: systemd enablement + DNS control

{% set is_wsl = grains.get('kernel_release', '').find('WSL') != -1 or
                 grains.get('kernel_release', '').find('Microsoft') != -1 %}

{% if is_wsl %}
wsl_config:
  file.managed:
    - name: /etc/wsl.conf
    - source: salt://linux/files/etc/wsl.conf.jinja
    - template: jinja
    - mode: 644
    - makedirs: True

# Note: Changes to /etc/wsl.conf require WSL shutdown/restart to take effect
# Run from Windows: wsl --shutdown
wsl_config_notification:
  test.show_notification:
    - text: |
        /etc/wsl.conf updated. Changes require WSL restart:
          Windows: wsl --shutdown
          Then: wsl
    - onchanges:
      - file: wsl_config
{% else %}
wsl_config:
  test.nop:
    - name: Skipping wsl.conf - not running on WSL
{% endif %}
