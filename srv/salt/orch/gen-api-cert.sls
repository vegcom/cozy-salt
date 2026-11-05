
# srv/salt/orch/gen-api-cert.sls
#
# Orchestration: generate Salt API TLS cert using x509 (modern)
# Run manually: salt-run state.orchestrate orch.gen-api-cert

ensure_api_dir:
  salt.function:
    - name: state.single
    - tgt: salt
    - arg:
        - file.directory
    - kwarg:
        name: /etc/salt/pki/api
        makedirs: true
        mode: "0755"
        user: salt
        group: salt

create_private_key:
  salt.function:
    - name: x509.create_private_key
    - tgt: salt
    - kwarg:
        path: /etc/salt/pki/api/salt.key
    - require:
        - salt: ensure_api_dir

enforce_private_key_permissions:
  salt.function:
    - name: state.single
    - tgt: salt
    - arg:
        - file.managed
    - kwarg:
        name: /etc/salt/pki/api/salt.key
        user: salt
        group: salt
        mode: "0600"
        replace: false
    - require:
        - salt: create_private_key

gen_api_cert:
  salt.function:
    - name: x509.create_certificate
    - tgt: salt
    - kwarg:
        path: /etc/salt/pki/api/salt.crt
        CN: salt
        days_valid: 3650
        signing_private_key: /etc/salt/pki/api/salt.key
    - require:
        - salt: enforce_private_key_permissions

store_cert_in_mine:
  salt.function:
    - name: mine.update
    - tgt: salt
    - require:
        - salt: gen_api_cert
