{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set ssh_enabled = salt['pillar.get']('host:services:ssh_enabled', not is_container) %}
{%- set ssh_service_name = 'sshd' if grains['os_family'] == 'Arch' else 'ssh' %}
{%- set is_wsl = grains.get('kernel_release', '').find('WSL') != -1 %}
{%- set ssh_port = 2222 if is_wsl else salt['pillar.get']('ssh:port', 22) %}
{%- if ssh_enabled %}
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://_templates/sshd_hardening.conf.jinja
    - template: jinja
    - mode: "0644"
    - makedirs: True
sshd_config:
  file.managed:
    - name: /etc/ssh/sshd_config
    - backup: .bak
    - contents: |
        # Managed by Salt - DO NOT EDIT MANUALLY
        Include /etc/ssh/sshd_config.d/*.conf
        Include /opt/cozy/etc/ssh/sshd_config.d/*.conf
        AuthorizedKeysFile .ssh/authorized_keys
        PasswordAuthentication yes
        KbdInteractiveAuthentication yes
        UsePAM yes
        X11Forwarding yes
        PrintMotd yes
        AcceptEnv LANG LC_* COLORTERM NO_COLOR
        Subsystem sftp internal://sftp-server
sshd_service:
  service.running:
    - name: {{ ssh_service_name }}
    - enable: True
    - watch:
      - file: sshd_config
{%- else %}
sshd_service:
  test.nop:
    - name: SSH service disabled (host:services:ssh_enabled = false)
{%- endif %}
