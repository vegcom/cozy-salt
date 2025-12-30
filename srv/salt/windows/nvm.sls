# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
# nvm-windows Chocolatey package installs to AppData, then configure for C:\opt\nvm
# Global npm packages installed via common.nvm orchestration

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

# Install global npm packages via common orchestration
include:
  - common.nvm
