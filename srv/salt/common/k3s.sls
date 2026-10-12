# Dynamically pulls runtime configs out of the Salt Mine and deploys them

{%- from '_macros/dotfiles.sls' import get_user_home %}
{%- set is_windows = grains['os'] == 'Windows' %}

{%- set all_mine_configs = salt['mine.get']('*', 'k3s_kubeconfig') %}
{%- set all_mine_metadata = salt['mine.get']('*', 'k3s_metadata') %}

{%- if all_mine_configs %}
  {%- if not is_windows %}
    {%- set usernames = salt['pillar.get']('managed_users', [], merge=True) %}
  {%- else %}
    {%- from '_macros/windows.sls' import get_users_with_profiles with context %}
    {%- set usernames = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
  {%- endif %}

  {%- for username in usernames %}
    {%- set user_home = get_user_home(username) | trim %}
    {%- if user_home %}

k3s_user_kube_dir_{{ username }}:
  file.directory:
    - name: {{ user_home }}/.kube/configs
    {%- if not is_windows %}
    - user: {{ username }}
    - group: cozyusers
    - mode: "0750"
    {%- endif %}
    - makedirs: True

      {%- for remote_host, kubeconfig_raw in all_mine_configs.items() %}
        {%- if kubeconfig_raw %}
          {%- set host_meta = all_mine_metadata.get(remote_host, {}) %}
          {%- set host_port = host_meta.get('port', '6443') %}

          {%- set needle = 'https://127.0.0.1:' ~ (host_port | string) %}
          {%- set target_server = 'https://' ~ remote_host ~ ':' ~ (host_port | string) %}
          {%- set kubeconfig = kubeconfig_raw | replace(needle, target_server) %}

k3s_user_kubeconfig_{{ username }}_{{ remote_host }}:
  file.managed:
    - name: {{ user_home }}/.kube/configs/{{ remote_host }}.conf
    - contents: {{ kubeconfig | yaml_encode }}
    {%- if not is_windows %}
    - user: {{ username }}
    - group: cozyusers
    - mode: "0600"
    {%- endif %}
    - show_changes: False
    - require:
      - file: k3s_user_kube_dir_{{ username }}

        {%- endif %}
      {%- endfor %}

    {%- endif %}
  {%- endfor %}
{%- else %}
k3s_multi_user_configs_skipped:
  test.nop:
    - name: "Skipping cross-platform user configs: No active cluster data found in the Salt Mine."
{%- endif %}
