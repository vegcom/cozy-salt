# Linux Homebrew installation
{# Path configuration from pillar with defaults #}
{%- set homebrew_base = salt['pillar.get']('install_paths:homebrew:linux', '/home/linuxbrew/.linuxbrew') %}
{# Extract parent directory for initial creation #}
{%- set homebrew_parent = homebrew_base.rsplit('/', 1)[0] if '/' in homebrew_base else '/home/linuxbrew' %}
{%- set service_user = salt['pillar.get']('service_user:name', 'cozy-salt-svc') %}

linuxbrew_directory:
  file.directory:
    - name: {{ homebrew_parent }}
    - user: {{ service_user }}
    - group: cozyusers
    - mode: "0775"
    - makedirs: True
    - order: 20
    - require:
      - user: {{ service_user }}_service_account

homebrew_install:
  cmd.run:
    - name: |
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    - runas: {{ service_user }}
    - env:
      - NONINTERACTIVE: 1
    - require:
      - file: linuxbrew_directory
    - creates: {{ homebrew_base }}/bin/brew

homebrew_svc_acl:
  cmd.run:
    - name: |
        setfacl -R -m u:{{ service_user }}:rwx {{ homebrew_base }}
        setfacl -R -m d:u:{{ service_user }}:rwx {{ homebrew_base }}
    - onlyif: test -d {{ homebrew_base }}
    - unless: getfacl {{ homebrew_base }} 2>/dev/null | grep -q "user:{{ service_user }}:rwx"
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

{%- from '_macros/packages.sls' import get_packages %}
{%- set packages = get_packages() | load_json %}
{%- set brew_packages = packages.get('brew', []) %}
{%- if brew_packages %}
  {%- set brew_cask = brew_packages.get('cask', []) %}
  {%- set brew_formula = brew_packages.get('formula', []) %}
  {%- if brew_formula %}
install_brew_formulas:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install {{ brew_formula | join(' ') }}
    - runas: {{ service_user }}
    - unless: test ! -x {{ homebrew_base }}/bin/brew
    - require:
      - cmd: homebrew_update
  {%- endif %}

  {%- if brew_cask %}
install_brew_casks:
  cmd.run:
    - name: {{ homebrew_base }}/bin/brew install --cask {{ brew_cask | join(' ') }}
    - runas: {{ service_user }}
    - unless: test ! -x {{ homebrew_base }}/bin/brew
    - require:
      - cmd: homebrew_update
  {%- endif %}
{%- endif %}
