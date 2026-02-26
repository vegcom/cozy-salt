#!jinja|yaml
# Arch Linux Pillar Data

{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {% set detected_user = 'root' %}
{% else %}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or salt['environ.get']('USER') or 'cozy-salt-svc' %}
{% endif %}

aur_user: {{ detected_user }}

pacman:
  repos:
    kde-unstable:
      enabled: false
      include: /etc/pacman.d/mirrorlist
    core:
      enabled: true
      include: /etc/pacman.d/mirrorlist
    extra:
      enabled: true
      include: /etc/pacman.d/mirrorlist
    multilib:
      enabled: true
      include: /etc/pacman.d/mirrorlist
    chaotic-aur:
      enabled: false
      siglevel: never
      server: https://builds.garudalinux.org/repos/$repo/$arch
