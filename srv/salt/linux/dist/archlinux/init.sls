{%- if grains['os_family'] == 'Arch' %}
include:
  - linux.dist.archlinux.pacman
  - linux.dist.archlinux.makepkg
  - linux.dist.archlinux.yay
  - linux.dist.archlinux.install
{%- else %}
# Not an Arch-based system, skipping pacman configuration
archlinux_config_skipped:
  test.nop:
    - name: Not an Arch-based system - skipping archlinux config
{%- endif %}
