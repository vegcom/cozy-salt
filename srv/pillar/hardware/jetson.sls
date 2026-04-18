#!jinja|yaml
# Nvidia Jetson Hardware Class
host:
  capabilities:
    k3s: true
    docker: true

managed_users:
  - nvidia
