# Linux configuration
# User environment, shell setup, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}
{% set dns = network_config.get('dns', {}) %}
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{% set is_wsl = salt['file.file_exists']('/proc/version') and
                'microsoft' in salt['cmd.run']('cat /proc/version 2>/dev/null || echo ""', python_shell=True).lower() %}
{# SSH port: 2222 for WSL (avoids Windows SSH on 22), 22 for native Linux #}
{% set ssh_port = 2222 if is_wsl else salt['pillar.get']('ssh:port', 22) %}

# NOTE: /etc/skel is now managed in linux/users.sls (must run before user.present)

# Deploy system-wide tmux configuration (Twilite theme)
tmux_system_config:
  file.managed:
    - name: /etc/tmux.conf
    - source: salt://linux/files/etc/tmux.conf
    - mode: 644

# Deploy profile.d initialization scripts
starship_profile:
  file.managed:
    - name: /etc/profile.d/starship.sh
    - source: salt://linux/files/etc-profile.d/starship.sh
    - mode: 644

miniforge_system_profile:
  file.managed:
    - name: /etc/profile.d/miniforge.sh
    - source: salt://linux/files/etc-profile.d/miniforge.sh
    - mode: 644

nvm_system_profile:
  file.managed:
    - name: /etc/profile.d/nvm.sh
    - source: salt://linux/files/etc-profile.d/nvm.sh
    - mode: 644

yay_wrapper_profile:
  file.managed:
    - name: /etc/profile.d/yay-wrapper.sh
    - source: salt://common/files/profile.d/yay-wrapper.sh
    - mode: 644

# Deploy hardened SSH configuration (consolidated template - High-003)
# Template handles platform conditionals: Linux, WSL, and Windows
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - mode: 644
    - makedirs: True

# Allow unauthenticated APT packages (trusted repositories) - Debian/Ubuntu only
{% if grains['os_family'] == 'Debian' %}
apt_allow_unauthenticated:
  file.managed:
    - name: /etc/apt/apt.conf.d/99-allow-unauthenticated
    - contents: |
        APT::Get::AllowUnauthenticated "true";
    - mode: 644
{% else %}
apt_allow_unauthenticated:
  test.nop:
    - name: Skipping APT config on non-Debian system
{% endif %}

# Manage /etc/hosts entries for network services (from pillar.network.hosts)
{% for hostname, ip in hosts.items() %}
hosts_entry_{{ hostname | replace('.', '_') }}:
  host.present:
    - name: {{ hostname }}
    - ip: {{ ip }}
{% endfor %}

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
    - mode: 644
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
