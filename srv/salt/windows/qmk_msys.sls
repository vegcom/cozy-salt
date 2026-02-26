{% set _pinned = salt['pillar.get']('versions:qmk_msys:version', '') %}
{% set qmk_msys_version = _pinned or salt['github_release.latest']('qmk/qmk_distro_msys') %}
{% set qmk_msys_path     = "C:\\opt\\qmk_msys" %}
{% set qmk_msys_tmp      = "$env:TEMP\\qmk_msys-install.exe" %}
{% set qmk_shortcut      = "C:\\opt\\qmk_msys\\QMK MSYS.lnk"%}
{% set qmk_uri           = "https://github.com/qmk/qmk_distro_msys/releases/download/" + qmk_msys_version + "/QMK_MSYS.exe" %}


# Create C:\opt\qmk_msys directory for consistency
qmk_msysdirectory:
  file.directory:
    - name: {{ qmk_msys_path }}
    - makedirs: True

# Download wt installer
qmk_msys_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri \"{{ qmk_uri }}\"
        -OutFile \"{{ qmk_msys_tmp }}\""
    - creates: {{ qmk_msys_tmp }}
    - require:
      - file: qmk_msysdirectory

qmk_msys_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& \"{{ qmk_msys_tmp }}\"
        /SP-
        /VERYSILENT
        /DIR={{ qmk_msys_path }}"
    - require:
      - cmd: qmk_msys_download
    - creates: {{ qmk_shortcut }}

include:
  - windows.paths
