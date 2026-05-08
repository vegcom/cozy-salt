# Orchestration: generate Salt API TLS cert on master and store in mine
# Triggered by reactor when guava (master) comes online as a minion
# Run manually: salt-run state.orchestrate orch.gen-api-cert

gen_api_cert:
  salt.function:
    - name: tls.create_self_signed_cert
    - tgt: salt
    - kwarg:
        cacert_path: /etc/salt/pki/api
        CN: salt
        days_valid: 3650

store_cert_in_mine:
  salt.function:
    - name: mine.update
    - tgt: salt
    - require:
      - salt: gen_api_cert
