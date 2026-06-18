{#- Gate on grain set by srv/salt/_grains/storage.py #}
{%- if grains.get('cozy_non_root_storage', False) %}
{%- set storage_path = grains.get('cozy_storage_path', '/storage') %}
docker:
  exec-opts: ["native.cgroupdriver=cgroupfs"]
  data-root: {{ storage_path }}/docker
k3s:
  data_dir: {{ storage_path }}/k3s
  kwargs_opt: "--data-dir={{ storage_path }}/k3s/"
{%- endif %}
