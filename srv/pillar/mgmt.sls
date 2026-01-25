#!jinja|yaml
# Management and service account configuration
# Used for provisioning operations that need elevated/service account access

service_user:
  # Service account name (used on both Windows and Linux)
  name: cozy-salt-svc
  # Service account password (for Windows creation, sudo on Linux if needed)
  # TODO: Move to secrets/init.sls when secrets management is ready
  password: "cozy"
