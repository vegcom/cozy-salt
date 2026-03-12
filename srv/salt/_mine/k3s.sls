{%- set k3s_data_dir = salt['pillar.get']('k3s:data_dir', '/var/lib/rancher/k3s') %}

mine_functions:
  k3s_kubeconfig:
    mine_function: file.read
    path: /etc/rancher/k3s/k3s.yaml
  k3s_node_token:
    mine_function: file.read
    path: {{ k3s_data_dir }}/server/node-token
