# Linux configuration
# User environment, shell setup, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}
{% set dns = network_config.get('dns', {}) %}

# Deploy skeleton files to /etc/skel for new users
skel_files:
  file.recurse:
    - name: /etc/skel
    - source: salt://linux/files/etc-skel
    - include_empty: True
    - clean: False

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

# Deploy hardened SSH configuration
# WSL systems get WSL-specific config (Port 2222), others get standard config
{% if grains.get('kernel_release', '').find('WSL') != -1 or grains.get('kernel_release', '').find('Microsoft') != -1 %}
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://wsl/files/etc-ssh/sshd_config.d/99-hardening.conf
    - mode: 644
    - makedirs: True
{% else %}
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://linux/files/etc-ssh/sshd_config.d/99-hardening.conf
    - mode: 644
    - makedirs: True
{% endif %}

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
# Container detection pattern from Homebrew install script:
# https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh (check_run_command_as_root)
# Detect containers: Docker, Podman/systemd-container, Kubernetes, Azure Pipelines
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
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
# Exports GIT_NAME and GIT_EMAIL from global git config for all users via /etc/profile.d
git_env_vars_profile:
  file.managed:
    - name: /etc/profile.d/git-env.sh
    - source: salt://linux/files/etc-profile.d/git-env.sh
    - mode: 644

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# Ensure SSH is configured on alternate port (for WSL/containers)
{% if grains.get('virtual', '') == 'container' or grains.get('is_wsl', False) %}
sshd_config_port:
  file.replace:
    - name: /etc/ssh/sshd_config
    - pattern: '^#?Port 22$'
    - repl: 'Port 2222'
    - backup: .bak

sshd_service:
  service.running:
    - name: ssh
    - enable: True
    - watch:
      - file: sshd_config_port
{% endif %}
