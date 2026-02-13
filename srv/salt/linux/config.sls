# Linux configuration
# User environment, shell setup, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set dns = network_config.get('dns', {}) %}
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{% set is_wsl = salt['file.file_exists']('/proc/version') and
                'microsoft' in salt['cmd.run']('cat /proc/version 2>/dev/null || echo ""', python_shell=True).lower() %}
{# SSH port: 2222 for WSL (avoids Windows SSH on 22), 22 for native Linux #}
{% set ssh_port = 2222 if is_wsl else salt['pillar.get']('ssh:port', 22) %}
{% set include_files = ['0-functions.sh', '1-alias.sh', '2-path.sh', '9-cozy-msg.sh', 'cozy.sh', 'zzz-cozy-board.sh'] %}

# NOTE: /etc/skel is now managed in linux/users.sls (must run before user.present)

# Deploy system-wide tmux configuration (Twilite theme)
tmux_system_config:
  file.managed:
    - name: /etc/tmux.conf
    - source: salt://linux/files/etc/tmux.conf
    - mode: "0644"

# Deploy profile.d initialization scripts
starship_profile:
  file.managed:
    - name: /etc/profile.d/starship.sh
    - source: salt://linux/files/etc-profile.d/starship.sh
    - mode: "0644"

miniforge_system_profile:
  file.managed:
    - name: /etc/profile.d/miniforge.sh
    - source: salt://linux/files/etc-profile.d/miniforge.sh
    - mode: "0644"

# nvm.sh deployed by linux/nvm.sls (avoid double deploy)

yay_wrapper_profile:
  file.managed:
    - name: /etc/profile.d/yay-wrapper.sh
    - source: salt://linux/files/etc-profile.d/yay-wrapper.sh
    - mode: "0755"

{% for include_file in include_files %}
cozy_etc_profiled_{{ include_file | replace('-', '_') }}:
  file.managed:
    - name: /etc/profile.d/{{ include_file }}
    - source: salt://linux/files/etc-profile.d/{{ include_file }}
    - mode: "0644"
{% endfor %}

cozy_etc_profile:
  file.managed:
    - name: /etc/profile
    - source: salt://linux/files/etc/profile
    - mode: "0644"

cozy_etc_bashrc:
  file.managed:
    - name: /etc/bash.bashrc
    - source: salt://linux/files/etc/bash.bashrc
    - mode: "0644"

cozy_etc_zsh:
  file.recurse:
    - name: /etc/zsh
    - source: salt://linux/files/etc-zsh/
    - include_empty: True
    - clean: True
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"

cozy_etc_zshrc:
  file.managed:
    - name: /etc/zshrc
    - source: salt://linux/files/etc/zshrc
    - mode: "0644"

cozy_opt_dir:
  file.directory:
    - name: /opt/cozy
    - source: salt://linux/files/opt-cozy
    - makedirs: True
    - mode: "0775"
    - order: 1
    - recurse:
      - user
      - group

cozy_opts:
  file.recurse:
    - name: /opt/cozy/bin/
    - source: salt://linux/files/opt-cozy
    - include_empty: True
    - clean: False
    - dir_mode: "0775"
    - file_mode: "0774"
    - order: 0
    - require:
      - file: cozy_opt_dir

# Generate banners during highstate
run_gen_motd:
  cmd.run:
    - name: /opt/cozy/bin/gen_motd.sh
    - require:
      - file: cozy_opts

run_gen_issue:
  cmd.run:
    - name: /opt/cozy/bin/gen_issue.sh
    - require:
      - file: cozy_opts

run_gen_issuenet:
  cmd.run:
    - name: /opt/cozy/bin/gen_issuenet.sh
    - require:
      - file: cozy_opts

# Silence pam_lastlog2 output on login (append 'silent' if missing)
{% if grains['os_family'] == 'Debian' %}
pam_lastlog2_silent:
  file.replace:
    - name: /etc/pam.d/common-session
    - pattern: '^(session\s+optional\s+pam_lastlog2\.so)(?!\s+silent)(.*)$'
    - repl: '\1 silent\2'
{% elif grains['os_family'] == 'Arch' %}
pam_lastlog2_silent:
  file.replace:
    - name: /etc/pam.d/system-login
    - pattern: '^(session\s+optional\s+pam_lastlog2\.so)(?!\s+silent)(.*)$'
    - repl: '\1 silent\2'
{% endif %}

# Deploy hardened SSH configuration (consolidated template - High-003)
# Template handles platform conditionals: Linux, WSL, and Windows
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True

# Allow unauthenticated APT packages (trusted repositories) - Debian/Ubuntu only
{% if grains['os_family'] == 'Debian' %}
apt_allow_unauthenticated:
  file.managed:
    - name: /etc/apt/apt.conf.d/99-allow-unauthenticated
    - contents: |
        APT::Get::AllowUnauthenticated "true";
    - mode: "0644"
{% else %}
apt_allow_unauthenticated:
  test.nop:
    - name: Skipping APT config on non-Debian system
{% endif %}

# Hosts entries managed in common.hosts (cross-platform)

# Configure DNS search domain (skip in containers - they have their own DNS)
{% if not is_container %}
dns_search_domain:
  file.managed:
    - name: /etc/resolv.conf
    - contents: |
        search {{ dns.get('search_domain', 'local') }}
        {% for nameserver in dns.get('nameservers', ['10.0.0.1', '1.1.1.1', '1.0.0.1']) %}
        nameserver {{ nameserver }}
        {% endfor %}
    - mode: "0644"
{% else %}
# DNS configuration skipped - running in container (Docker/Podman/Kubernetes)
skip_dns_config:
  test.nop:
    - name: Skipping resolv.conf management in container environment
{% endif %}

# Deploy system-wide git environment variables initialization
# Exports GIT_NAME and GIT_EMAIL from global git config for all users
# Implementation delegated to common.git_env module (platform-specific)
include:
  - common.git_env
  - linux.config-steamdeck

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# SSH service management - controlled by pillar host:services:ssh_enabled
{% set ssh_enabled = salt['pillar.get']('host:services:ssh_enabled', not is_container) %}
{# SSH service name varies by distro: Arch=sshd, Debian/RHEL=ssh #}
{% set ssh_service_name = 'sshd' if grains['os_family'] == 'Arch' else 'ssh' %}

{% if ssh_enabled %}
sshd_config_port:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^#?Port \d+$'
    - repl: 'Port {{ ssh_port }}'
    - backup: .bak

sshd_service:
  service.running:
    - name: {{ ssh_service_name }}
    - enable: True
    - watch:
      - file: sshd_config_port
{% else %}
sshd_service:
  test.nop:
    - name: SSH service disabled (host:services:ssh_enabled = false)
{% endif %}

etc_systemd_system_units:
  file.directory:
    - name: /etc/systemd/system
    - user: root
    - group: root
    - mode: "0755"

etc_systemd_user_units:
  file.directory:
    - name: /etc/systemd/user
    - user: root
    - group: root
    - mode: "0755"

cozy_etc_systemd_system:
  file.recurse:
    - name: /etc/systemd/system
    - source: salt://linux/files/etc-systemd-system
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"

cozy_etc_systemd_user_units:
  file.recurse:
    - name: /etc/systemd/user
    - source: salt://linux/files/etc-systemd-user
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"

etc_environment.d:
  file.managed:
    - name: /etc/environment.d/cozy.conf
    - source: salt://linux/files/etc-environment.d/cozy.conf
    - mode: "0644"
    - makedirs: True
