# Windows Node.js version management via nvm-windows
# System-wide installation to C:\opt\nvm (consistent with Linux /opt/nvm)
# nvm-windows Chocolatey package installs to AppData, then configure for C:\opt\nvm
# Global npm packages installed via common.nvm orchestration

{% set nvm_config = salt['pillar.get']('nvm', {}) %}
# nvm on windows does not accept wildcards
{% set default_version = nvm_config.get('default_version', 'lts') %}

# Create C:\opt\nvm directory for consistency
nvm_directory:
  file.directory:
    - name: C:\opt\nvm
    - makedirs: True

# Set system-wide environment variable for NVM_HOME
# nvm-windows will use this location for Node.js versions
nvm_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: NVM_HOME
    # TODO: pillar "C:\opt\nvm"
    - vdata: C:\opt\nvm
    - vtype: REG_SZ
    - require:
      - file: nvm_directory

# Install default Node.js version
install_default_node_version:
  cmd.run:
    # XXX: nvm alias - does not work on NVM for Windows
    - name: nvm install {{ default_version }}
    - shell: pwsh
    - unless: nvm list | findstr "{{ default_version }}"
    # XXX: NVM_HOME is not loaded from nvm_home corectly in shell
    - env:
      - NVM_HOME: C:\opt\nvm
    - require:
      - reg: nvm_home

# Install global npm packages via common orchestration
include:
  - common.nvm
