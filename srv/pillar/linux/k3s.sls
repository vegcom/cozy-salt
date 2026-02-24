k3s:
  args: ""

  channel: "latest"

  # Role "server" should be set on at least one host via srv/pillar/host/example.sls
  role: agent
