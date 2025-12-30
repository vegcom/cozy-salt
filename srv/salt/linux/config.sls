# Linux configuration
# User environment, shell setup, and system configuration

{% set network_config = salt['pillar.get']('network', {}) %}
{% set hosts = network_config.get('hosts', {}) %}
{% set dns = network_config.get('dns', {}) %}
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}

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
# Exports GIT_NAME and GIT_EMAIL from global git config for all users via /etc/profile.d
git_env_vars_profile:
  file.managed:
    - name: /etc/profile.d/git-env.sh
    - source: salt://linux/files/etc-profile.d/git-env.sh
    - mode: 644

# ============================================================================
# Service Management (merged from services.sls)
# ============================================================================

# SSH service management (skip in containers - sshd not available)
{% if not is_container %}
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
{% else %}
sshd_service:
  test.nop:
    - name: Skipping SSH service in container
{% endif %}
