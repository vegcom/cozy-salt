{%- if grains['os_family'] == 'Windows' %}
  {%- set minion_conf_dir = 'C:/salt/conf' %}
{%- else %}
  {%- set minion_conf_dir = '/etc/salt' %}
{%- endif %}
{%- set minion_conf = minion_conf_dir ~ '/minion.d' %}
{%- set ipfs_mine_conf = minion_conf ~ "/mine_ipfs.conf" %}

ipfs_mine:
  file.managed:
    - name: {{ ipfs_mine_conf }}
    - source: salt://_templates/ipfs-mine.conf.jinja
    - template: jinja
    - makedirs: True
    {%- if grains['os_family'] != 'Windows' %}
    - mode: '0644'
    {%- endif %}
