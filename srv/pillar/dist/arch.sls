#!jinja|yaml
# Arch Linux Pillar Data

{% if salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] %}
  {% set detected_user = 'root' %}
{% else %}
  {% set detected_user = salt['environ.get']('SUDO_USER') or salt['environ.get']('LOGNAME') or salt['environ.get']('USER') or 'admin' %}
{% endif %}

aur_user: {{ detected_user }}

{% set cpu_arch = salt['pillar.get']('cpu_arch', 'x86_64') %}
pacman:
  repos:
    kde-unstable:
      enabled: true
      Include: /etc/pacman.d/mirrorlist
    core:
      enabled: true
      Include: /etc/pacman.d/mirrorlist
    extra:
      enabled: true
      Include: /etc/pacman.d/mirrorlist
    multilib:
      enabled: true
      Include: /etc/pacman.d/mirrorlist
