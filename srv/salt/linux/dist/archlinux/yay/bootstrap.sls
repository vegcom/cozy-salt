{#-
  TODO: consider moving `/home/{{ service_user }}/.cache/yay-bootstrap` to a path in `/opt/cozy`
        maybe not cache, but something fitting
          - this would enable us to switch from yay-bin to yay proper, and sidestep some redundancy .hooks.sls
#}
{%- set service_user = salt['pillar.get']('aur_user', 'cozy-salt-svc') %}

# ============================================================================
# YAY BOOTSTRAP: Clone and build yay-bin from AUR
# Runs as aur_user since makepkg cannot run as root
# ============================================================================
yay_build_dir:
  file.directory:
    - name: /home/{{ service_user }}/.cache/yay-bootstrap
    - user: {{ service_user }}
    - group: {{ service_user }}
    - mode: "0755"
    - makedirs: True

yay_clone:
  git.latest:
    - name: https://aur.archlinux.org/yay-bin.git
    - target: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - user: {{ service_user }}
    - force_clone: True
    - require:
      - file: yay_build_dir
    - unless: which yay

yay_install:
  cmd.run:
    - name: makepkg -si --noconfirm
    - cwd: /home/{{ service_user }}/.cache/yay-bootstrap/yay-bin
    - runas: {{ service_user }}
    - env:
      - HOME: /home/{{ service_user }}
      - USER: {{ service_user }}
      - LANG: C.UTF-8
      - PATH: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    - require:
      - git: yay_clone
    - unless: which yay
