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
