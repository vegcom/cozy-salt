#!jinja|yaml
# Management and service account configuration
# Used for provisioning operations that need elevated/service account access
# TODO: Move to secrets/init.sls when secrets management is ready

service_user:
  name: cozy-salt-svc
