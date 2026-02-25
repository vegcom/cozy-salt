# Linux Homebrew installation
{# Path configuration from pillar with defaults #}
{% set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}
{# Extract parent directory for initial creation #}
{% set homebrew_parent = homebrew_base.rsplit('/', 1)[0] if '/' in homebrew_base else '/home/linuxbrew' %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}

linuxbrew_directory:
  file.directory:
    - name: {{ homebrew_parent }}
    - user: {{ service_user }}
    - group: cozyusers
    - mode: "0775"
    - makedirs: True
    - order: 20

homebrew_install:
  cmd.run:
    - name: |
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - runas: {{ service_user }}
    - env:
      - NONINTERACTIVE: 1
    - creates: {{ homebrew_base }}/bin/brew
    - require:
      - file: linuxbrew_directory

homebrew_svc_acl:
  acl.present:
    - name: {{ homebrew_base }}
    - acl_type: user
    - acl_name: {{ service_user }}
    - perms: rwx
    - recurse: True
    - require:
      - cmd: homebrew_install

homebrew_svc_acl_default:
  acl.present:
    - name: {{ homebrew_base }}
    - acl_type: default:user
    - acl_name: {{ service_user }}
    - perms: rwx
    - require:
      - cmd: homebrew_install

homebrew_update:
  cmd.run:
    - name: |
        git config --global --add safe.directory {{ homebrew_base }}/Homebrew
        cd {{ homebrew_base }}/Homebrew
        if ! git remote get-url origin >/dev/null 2>&1; then
          git remote add origin https://github.com/Homebrew/brew.git
        fi
        {{ homebrew_base }}/bin/brew update || true
    - runas: {{ service_user }}
    - require:
      - cmd: homebrew_install
    - unless: test -f {{ homebrew_base }}/var/homebrew/.last_update_timestamp

{% import_yaml "packages.sls" as packages %}
{% set brew_packages = packages.get('brew', []) %}
{% if brew_packages %}
install_brew_packages:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install {{ brew_packages | join(' ') }}
    - runas: {{ service_user }}
    - unless: test ! -x {{ homebrew_base }}/bin/brew
    - require:
      - cmd: homebrew_update
{% endif %}
