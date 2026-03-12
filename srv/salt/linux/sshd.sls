# SSH service management - controlled by pillar host:services:ssh_enabled
{% set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{% set ssh_enabled = salt['pillar.get']('host:services:ssh_enabled', not is_container) %}
{% set ssh_service_name = 'sshd' if grains['os_family'] == 'Arch' else 'ssh' %}
{% set is_wsl = grains.get('kernel_release', '').find('WSL') != -1 %}
{% set ssh_port = 2222 if is_wsl else salt['pillar.get']('ssh:port', 22) %}

sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True

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
