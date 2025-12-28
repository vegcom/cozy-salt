# Linux service management
# Configure and manage system services

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
