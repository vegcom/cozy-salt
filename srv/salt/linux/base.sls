# Linux Base State
# Orchestration only - packages defined in provisioning/packages.sls

{% import_yaml 'packages.sls' as packages %}

# Install base packages from consolidated list
base_packages:
  pkg.installed:
    - pkgs:
{% if grains['os_family'] == 'Debian' %}
{% for pkg in packages.apt %}
      - {{ pkg }}
{% endfor %}
{% elif grains['os_family'] == 'RedHat' %}
{% for pkg in packages.dnf %}
      - {{ pkg }}
{% endfor %}
{% endif %}

# Deploy skeleton files to /etc/skel for new users
skel_files:
  file.recurse:
    - name: /etc/skel
    - source: salt://linux/files/etc-skel
    - include_empty: True
    - clean: False

# Deploy starship profile script (installation handled by the script itself)
starship_profile:
  file.managed:
    - name: /etc/profile.d/starship.sh
    - source: salt://linux/files/etc-profile.d/starship.sh
    - mode: 755

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
