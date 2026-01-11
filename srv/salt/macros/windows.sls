# Windows-specific Jinja macros for consistent environment setup
# Usage: {%- from "macros/windows.sls" import win_cmd %}

{#-
Macro: win_cmd
Purpose: Wrap Windows cmd.run with standard environment variables
This ensures consistent tool paths (NVM_HOME, NVM_SYMLINK, CONDA_HOME) across all Windows states

Parameters:
  command: The command to execute (string)
  extra_env: Optional dict of additional environment variables to set

Default environment variables (from pillar or defaults):
  - NVM_HOME: C:\opt\nvm (or from pillar.install_paths.nvm.windows)
  - NVM_SYMLINK: C:\opt\nvm\nodejs (or from pillar.install_paths.nvm.windows + \nodejs)
  - CONDA_HOME: C:\opt\miniforge3 (or from pillar.install_paths.miniforge.windows)

Example usage:
  {%- from "macros/windows.sls" import win_cmd %}

  install_nvm:
    cmd.run:
      - name: {{ win_cmd('nvm install lts') }}
      - shell: pwsh

Example with extra environment variables:
  {%- from "macros/windows.sls" import win_cmd %}

  build_project:
    cmd.run:
      - name: {{ win_cmd('build.exe', {'RUST_BACKTRACE': '1'}) }}
      - shell: pwsh
-#}

{%- macro win_cmd(command, extra_env=None) -%}
  {%- set nvm_path = salt['pillar.get']('install_paths:nvm:windows', 'C:\\opt\\nvm') -%}
  {%- set node_path = nvm_path ~ '\\nodejs' -%}
  {%- set miniforge_path = salt['pillar.get']('install_paths:miniforge:windows', 'C:\\opt\\miniforge3') -%}

  {%- set env_vars = {
    'NVM_HOME': nvm_path,
    'NVM_SYMLINK': node_path,
    'CONDA_HOME': miniforge_path
  } -%}

  {%- if extra_env -%}
    {%- do env_vars.update(extra_env) -%}
  {%- endif -%}

  {%- set env_lines = [] -%}
  {%- for key, value in env_vars.items() -%}
    {%- do env_lines.append('$env:' ~ key ~ ' = "' ~ value ~ '"') -%}
  {%- endfor -%}

{{ env_lines | join('; '); }}; {{ command }}
{%- endmacro -%}
