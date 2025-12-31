# Common Miniforge/Conda package orchestration
# Installs pip packages in miniforge base environment (cross-platform)
# Platform-specific miniforge installation delegated to linux.miniforge or windows.miniforge

{% import_yaml "provisioning/packages.sls" as packages %}

# Install pip base packages in miniforge base environment
{% for package in packages.get('pip_base', []) %}
install_pip_base_{{ package | replace('-', '_') }}:
  cmd.run:
    {% if grains['os_family'] == 'Windows' %}
    - name: C:\opt\miniforge3\Scripts\pip.exe install {{ package }}
    - shell: pwsh
    - unless: C:\opt\miniforge3\Scripts\pip.exe show {{ package }}
    - require:
      - cmd: miniforge_install
    {% else %}
    - name: /opt/miniforge3/bin/pip install {{ package }}
    - unless: /opt/miniforge3/bin/pip show {{ package }}
    - require:
      - cmd: miniforge_install
    {% endif %}
{% endfor %}
