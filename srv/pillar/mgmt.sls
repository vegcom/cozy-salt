#!jinja|yaml
# Management and service account configuration
# Used for provisioning operations that need elevated/service account access
# Use secrets/init.sls for secrets management ( e.g. password )

service_user:
  name: cozy-salt-svc
