# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
# nvm-windows Chocolatey package installs to AppData, then configure for C:\opt\nvm

{% set nvm_config = salt['pillar.get']('nvm', {}) %}
{% set default_version = nvm_config.get('default_version', 'lts/*') %}

# Create C:\opt\nvm directory for consistency
nvm_directory:
  file.directory:
    - name: C:\opt\nvm
    - makedirs: True

# Set system-wide environment variable for NVM_HOME
# nvm-windows will use this location for Node.js versions
nvm_environment_variables:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vtype: REG_SZ
    - entries:
      - NVM_HOME: C:\opt\nvm
    - require:
      - file: nvm_directory

# Install default Node.js version
install_default_node_version:
  cmd.run:
    - name: nvm install {{ default_version }} && nvm use {{ default_version }} && nvm alias default {{ default_version }}
    - shell: powershell
    - unless: nvm list | findstr "{{ default_version }}"
    - require:
      - reg: nvm_environment_variables

{% for package in packages.npm_global %}
install_npm_{{ package | replace('/', '_') | replace('@', '') | replace('-', '_') }}:
  cmd.run:
    - name: npm install -g {{ package }}
    - shell: powershell
    - require:
      - cmd: install_default_node_version
    - unless: npm list -g --depth=0 | findstr "{{ package }}"
{% endfor %}
