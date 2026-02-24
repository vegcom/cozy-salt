# Service account creation for system-level operations (Linux)
# Runs early before operations that depend on it
# Minimal privileges: no dotfiles, no git, no shell access
# Used for package installation and other provisioning tasks

{% set service_user = salt['pillar.get']('service_user', {}) %}
{% set svc_name = service_user.get('name', 'cozy-salt-svc') %}
{% set svc_password = service_user.get('password', '') %}

# Create service account with /bin/false shell (no interactive login needed)
{{ svc_name }}_service_account:
  user.present:
    - name: {{ svc_name }}
    - fullname: Cozy Salt Service Account
    - password: {{ svc_password }}
    - shell: /bin/false
    - home: /var/lib/cozy-salt-svc
    - createhome: True
    - groups: []

# sudoers for cozy-salt-svc user operations (NOPASSWD)
{{ svc_name }}_sudoers:
  file.managed:
    - name: /etc/sudoers.d/cozy-salt-svc
    - contents: |
        Cmnd_Alias PACMAN_CMDS = /usr/bin/pacman, /usr/bin/pacman-key, /usr/bin/pacstrap
        Cmnd_Alias MGMT_CMDS = /usr/bin/iptables
        Cmnd_Alias SYSTEMD_CMDS = /usr/bin/systemctl, /usr/bin/journalctl, /usr/bin/systemd-resolve
        {{ svc_name }} ALL=(ALL:ALL) NOPASSWD: PACMAN_CMDS, SYSTEMD_CMDS, MGMT_CMDS
    - mode: "0440"
    - user: root
    - group: root
    - makedirs: True
    - require:
      - group: cozyusers_group
