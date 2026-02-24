#!jinja|yaml
# Arch Linux Pillar Data

{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {% set detected_user = 'root' %}
{% else %}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or salt['environ.get']('USER') or 'admin' %}
{% endif %}

aur_user: {{ detected_user }}

pacman:
  repos:
    kde-unstable:
      enabled: false
      include: /etc/pacman.d/mirrorlist
      server: https://repo.c48.uk/arch/$repo/os/$arch
    core:
      enabled: true
      include: /etc/pacman.d/mirrorlist
      server: https://repo.c48.uk/arch/$repo/os/$arch
    extra:
      enabled: true
      include: /etc/pacman.d/mirrorlist
      server: https://repo.c48.uk/arch/$repo/os/$arch
    multilib:
      enabled: true
      include: /etc/pacman.d/mirrorlist
      server: https://repo.c48.uk/arch/$repo/os/$arch
    chaotic-aur:
      enabled: true
      server: https://builds.garudalinux.org/repos/$repo/$arch
