k3s:
  channel: "latest"
  # Role "server" should be set on at least one host via srv/pillar/host/example.sls
  role: agent

mine_functions:
  k3s_kubeconfig:
    mine_function: file.read
    path: /etc/rancher/k3s/k3s.yaml
  k3s_node_token:
    mine_function: file.read
    path: /storage/k3s/server/node-token
