# Windows Node.js version management via nvm-windows
# System-wide installation to C:\\opt\\nvm (consistent with Linux /opt/nvm)
# nvm-windows Chocolatey package installs to AppData, then configure for C:\\opt\\nvm
# Global npm packages installed via common.nvm orchestration
# ref: https://jrsoftware.org/ishelp/index.php?topic=setupcmdline
# nvm on windows does not accept wildcards
# FIXME: Need to swap to https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-noinstall.zip. current flags not working safely.
# TODO: nvm-setup.exe needs to be changed for nvm-noinstall.zip
# XXX: nvm alias - does not work on NVM for Windows
# Set system-wide environment variable for NVM_HOME
# nvm-windows will use this location for Node.js versions

{% set nvm_config   = salt['pillar.get']('nvm', {}) %}
{% set nvm_version  = nvm_config.get('default_version', 'lts') %}
{% set npm_pkg      = "https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-noinstall.zip" %}
{% set nvm_tmp      = "$env:TEMP\\nvm-noinstall.zip" %}
{% set nvm_path     = 'C:\\opt\\nvm' %}
{% set nvm_bin      = 'C:\\opt\\nvm\\nvm.exe' %}
{% set npm_settings = 'C:\\opt\\nvm\\settings.txt' %}
{% set node_path    = 'C:\\opt\\nvm\\nodejs' %}
{% set current_path = salt['reg.read_value']('HKLM',"SYSTEM\CurrentControlSet\Control\Session Manager\Environment",'Path').get('vdata','') %}

# Merge paths if absent - FIX: Use directory, not executable
{% set paths = current_path.split(';') %}

{% if nvm_path not in paths %}
  {% do paths.append(nvm_path) %}
{% endif %}

{% if node_path not in paths %}
  {% do paths.append(node_path) %}
{% endif %}

{% set merged_paths = ';'.join(paths) %}

nvm_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "Invoke-WebRequest -Uri '{{ npm_pkg }}' -OutFile {{ nvm_tmp }}"
    - creates: {{ nvm_tmp }}

nvm_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "Expand-Archive -Path {{ nvm_tmp }} -DestinationPath {{ nvm_path }} -Force"
    - creates: {{ nvm_bin }}
    - require:
      - cmd: nvm_download

nvm_npm_settings:
  file.managed:
    - name: {{ npm_settings }}
    - contents:
      - 'root: {{ nvm_path}}'
      - 'path: {{ node_path }}'
      - 'symlink: {{ node_path }}'
    - require:
      - cmd: nvm_install
    - creates: {{ npm_settings }}

nvm_home:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: NVM_HOME
    - vdata: {{ nvm_path }}
    - vtype: REG_SZ
    - require:
      - cmd: nvm_install

# NVM_SYMLINK tells nvm-windows where to create the active node symlink/junction
nvm_symlink:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: NVM_SYMLINK
    - vdata: {{ node_path }}
    - vtype: REG_SZ
    - require:
      - cmd: nvm_install

install_default_node_version:
  cmd.run:
    - name: {{ nvm_bin }} install {{ nvm_version }}
    - shell: pwsh
    - unless: {{ nvm_bin }} list | findstr "{{ nvm_version }}"
    - env:
      - NVM_HOME: {{ nvm_path }}
      - NVM_SYMLINK: {{ node_path }}
    - require:
      - cmd: nvm_install
      - file: nvm_npm_settings
      - reg: nvm_symlink

# Remove nodejs directory if it exists as real directory (not symlink)
# nvm use needs to create this as a junction/symlink
nvm_nodejs_dir_cleanup:
  cmd.run:
    - name: >
        pwsh -NoLogo -NoProfile -Command
        "if ((Test-Path '{{ node_path }}') -and -not ((Get-Item '{{ node_path }}').Attributes -band [IO.FileAttributes]::ReparsePoint)) { Remove-Item -Path '{{ node_path }}' -Recurse -Force }"
    - require:
      - cmd: install_default_node_version

# Activate the installed node version (creates symlink)
nvm_use_default:
  cmd.run:
    - name: {{ nvm_bin }} use {{ nvm_version }}
    - shell: pwsh
    - env:
      - NVM_HOME: {{ nvm_path }}
      - NVM_SYMLINK: {{ node_path }}
    - require:
      - cmd: nvm_nodejs_dir_cleanup
      - reg: nvm_symlink
    - creates: {{ node_path }}\node.exe

nvm_path_update:
  reg.present:
    - name: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
    - vname: Path
    - vtype: REG_EXPAND_SZ
    - vdata: {{ merged_paths }}
    - require:
      - cmd: nvm_install
      - file: nvm_npm_settings

# Install global npm packages via common orchestration
include:
  - common.nvm