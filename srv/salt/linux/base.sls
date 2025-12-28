# Linux Base State
# Applies to all Linux systems (Debian/Ubuntu, RHEL/CentOS)

# Ensure base packages are installed
base_packages:
  pkg.installed:
    - pkgs:
      - curl
      - wget
      - git
      - vim
      - htop
      - rsync

# Deploy skeleton files to /etc/skel for new users
skel_files:
  file.recurse:
    - name: /etc/skel
    - source: salt://linux/files/etc-skel
    - include_empty: True
    - clean: False

# Install Starship prompt
install_starship:
  cmd.run:
    - name: curl -sS https://starship.rs/install.sh | sh -s -- -y
    - creates: /usr/local/bin/starship

# Deploy starship profile script
starship_profile:
  file.managed:
    - name: /etc/profile.d/starship.sh
    - source: salt://linux/files/etc-profile.d/starship.sh
    - mode: 644
    - require:
      - cmd: install_starship

# Ensure SSH is configured on alternate port (for WSL compatibility)
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

