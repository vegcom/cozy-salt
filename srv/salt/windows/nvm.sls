# Windows Node.js version management via nvm-windows
# System-wide installation to C:\\opt\\nvm (consistent with Linux /opt/nvm)
# nvm-windows Chocolatey package installs to AppData, then configure for C:\\opt\\nvm
# Global npm packages installed via common.nvm orchestration
# ref: https://jrsoftware.org/ishelp/index.php?topic=setupcmdline

{% set nvm_config = salt['pillar.get']('nvm', {}) %}
# nvm on windows does not accept wildcards
{% set default_version = nvm_config.get('default_version', 'lts') %}

# Create C:\\opt\\nvm directory for consistency
nvm_directory_prune:
  file.directory:
    - name: C:\\opt\\nvm
    - clean: True
    - unless: C:\\opt\\nvm\\nvm.exe

# Create C:\\opt\\nvm directory for consistency
nvm_directory:
  file.directory:
    - name: C:\\opt\\nvm
    - makedirs: True
    - creates: C:\\opt\\nvm

nvm_npm_settings:
  file.managed:
    - name: C:\\opt\\nvm\settings.txt
    - contents:
      - 'root: C:\\opt\\nvm'
      - 'path: C:\\opt\\nvm\nodejs'
    - require:
      - file: nvm_directory
    - creates: C:\\opt\\nvm\settings.txt

nvm_download:
  cmd.run:
    # FIXME: Need to swap to https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-noinstall.zip. current flags not working safely.
    - name: "-Command Invoke-WebRequest -Uri https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-setup.exe -OutFile C:\Windows\Temp\nvm-setup.exe"
    - creates: C:\Windows\Temp\nvm-setup.exe
    - shell: pwsh
    - require:
      - file: nvm_directory
      - file: nvm_npm_settings
    # TODO: nvm-setup.exe needs to be changed for nvm-noinstall.zip
    - creates: C:\Windows\Temp\nvm-setup.exe

nvm_install:
  cmd.run:
    - name: "-Command Start-Process cmd.exe -WindowStyle Hidden -ArgumentList /C START /WAIT C:\Windows\Temp\nvm-setup.exe /ALLUSERS /NORESTART /SAVEINF=C:\\opt\\nvm\installation_settings.txt /SUPPRESSMSGBOXES /SP- /VERYSILENT /DIR=C:\\opt\\nvm"
    - shell: pwsh
    - require:
      - cmd: nvm_download
    - creates: C:\\opt\\nvm\nvm.exe

# Set system-wide environment variable for NVM_HOME
# nvm-windows will use this location for Node.js versions
nvm_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: NVM_HOME
    - vdata: C:\\opt\\nvm
    - vtype: REG_SZ
    - require:
      - cmd: nvm_install

# Install default Node.js version
install_default_node_version:
  cmd.run:
    # XXX: nvm alias - does not work on NVM for Windows
    - name: nvm install {{ default_version }}
    - shell: pwsh
    - unless: nvm list | findstr "{{ default_version }}"
    # XXX: NVM_HOME is not loaded from nvm_home corectly in shell
    - env:
      - NVM_HOME: C:\\opt\\nvm
    - require:
      - cmd: nvm_install

# Install global npm packages via common orchestration
include:
  - common.nvm
