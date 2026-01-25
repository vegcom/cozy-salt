# Service account creation for system-level operations
# Runs early before package installation states that depend on it
# Service account: used for winget, system packages, and other privileged operations

{% set service_user = salt['pillar.get']('service_user', {}) %}
{% set svc_name = service_user.get('name', 'cozy-salt-svc') %}
{% set svc_password = service_user.get('password', '') %}

# Create service account
{{ svc_name }}_service_account:
  user.present:
    - name: {{ svc_name }}
    - fullname: "Cozy Salt Service Account"
    - password: {{ svc_password }}
    - enforce_password: True
    - password_lock: False
    - groups:
      - Administrators

# Initialize service account profile (ensure it exists)
{{ svc_name }}_initialize_profile:
  cmd.run:
    - name: whoami
    - runas: {{ svc_name }}
    - shell: cmd
    - require:
      - user: {{ svc_name }}_service_account
