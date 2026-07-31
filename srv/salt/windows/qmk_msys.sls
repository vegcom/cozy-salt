{%- set _pinned = salt['pillar.get']('versions:qmk_msys:version', '') %}
{%- set qmk_msys_version = _pinned or salt['github_release.latest']('qmk/qmk_distro_msys') %}
{%- set qmk_msys_path = "C:/opt/qmk_msys" %}
{%- set qmk_msys_tmp = "C:/opt/cozy/cache/qmk_msys-install.exe" %}
{%- set qmk_shortcut = "C:/opt/qmk_msys/QMK MSYS.lnk" %}
{%- set qmk_uri = "https://github.com/qmk/qmk_distro_msys/releases/download/" + qmk_msys_version + "/QMK_MSYS.exe" %}

# Create C:\opt\qmk_msys directory for consistency
qmk_msysdirectory:
  file.directory:
    - name: {{ qmk_msys_path }}
    - makedirs: True

qmk_msys_download:
  file.managed:
    - name: {{ qmk_msys_tmp }}
    - source: {{ qmk_uri }}
    - skip_verify: True
    - mkdirs: True

qmk_msys_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& \"{{ qmk_msys_tmp }}\"
        /SP-
        /VERYSILENT
        /DIR={{ qmk_msys_path }}"
    - require:
      - file: qmk_msys_download

include:
  - windows.paths
