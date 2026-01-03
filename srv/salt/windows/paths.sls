# Windows PATH management
# Consolidated here to avoid race conditions between individual state files
# Single reg.present that reads current PATH and adds all opt paths at once

{% set opt_paths = [
  'C:\\opt\\nvm',
  'C:\\opt\\nvm\\nodejs',
  'C:\\opt\\rust\\bin',
  'C:\\opt\\miniforge3\\Scripts',
  'C:\\opt\\miniforge3'
] %}

{% set current_path = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','') %}

# Merge paths if absent
{% set paths = current_path.split(';') %}

{% for p in opt_paths %}
  {% if p not in paths %}
    {% do paths.append(p) %}
  {% endif %}
{% endfor %}

{% set merged_paths = ';'.join(paths) %}

opt_paths_update:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: {{ merged_paths }}
