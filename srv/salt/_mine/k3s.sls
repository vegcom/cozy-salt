{%- set is_container = salt['file.file_exists']('/.dockerenv') or
                      salt['file.file_exists']('/run/.containerenv') %}
{%- set k3s_data_dir = salt['pillar.get']('k3s:data_dir', '/var/lib/rancher/k3s') %}

{%- if not is_container %}
mine_functions:
  k3s_kubeconfig:
    mine_function: file.read
    path: /etc/rancher/k3s/k3s.yaml

  k3s_node_token:
    mine_function: file.read
    path: {{ k3s_data_dir }}/server/node-token

  k3s_metadata:
    mine_function: grains.item
    items:
      - id
    {%- set metadata = {
      'server': salt['pillar.get']('k3s:server', 'https://k3s-server:6443'),
      'role': salt['pillar.get']('k3s:role', 'agent'),
      'port': salt['pillar.get']('k3s:port', '6443')
    } %}
    extra_dict: {{ metadata | json }}
{%- else %}
mine_functions:
  test.nop:
    - name: Skipping k3s_kubeconfig mine
{%- endif %}
