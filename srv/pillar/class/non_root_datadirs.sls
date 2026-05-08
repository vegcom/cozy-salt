{#- Linux only at time of writing #}
{%- if grains['kernel'] == "Linux" %}
  {%- set root_dev = salt['mount.get_device_from_path']("/") %}
  {%- set root_blkid = salt['disk.blkid'](root_dev) %}
  {%- if not root_blkid %}{%- set on_separate_dev = false %}{%- else %}
  {%- set root_dev = root_blkid.keys() | list | first %}
  {%- set root_uuid = root_blkid[root_dev]['UUID'] %}
  {%- set root_info = {root_dev: root_uuid} %}
  {%- set data_path = salt['pillar.get']("docker:data_dir", "/storage/docker") %}
  {%- if data_path %}
    {%- set data_dev = salt['mount.get_device_from_path'](data_path) %}
    {%- set data_blkid = salt['disk.blkid'](data_dev) %}
    {%- set data_dev = data_blkid.keys() | list | first %}
    {%- set data_uuid = data_blkid[data_dev]['UUID'] %}
    {%- set data_info = {data_dev: data_uuid} %}
    {%- set data_fs = salt['disk.get_fstype_from_path'](data_path) %}
  {%- else %}
    {%- set data_blkid = None %}
    {%- set data_fs = None %}
  {%- endif %}
  {%- set on_separate_dev = (data_uuid != root_uuid) and (data_dev != root_dev) %}
  docker:
    insecure-registries: ["guava:5000"]
    exec-opts: ["native.cgroupdriver=cgroupfs"]
  {%- if on_separate_dev %}
    data-root: {{ data_path }}
  {%- endif %}
  {%- if on_separate_dev %}
  k3s:
    data_dir: /storage/k3s
    kwargs_opt: "--data-dir=/storage/k3s/"
  {%- endif %}
  {%- endif %}{#- end root_blkid check #}
{%- endif %}
