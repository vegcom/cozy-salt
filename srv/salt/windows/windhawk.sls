{%- set _pinned = salt['pillar.get']('versions:windhawk:version', '') %}
{%- set windhawk_version = _pinned or salt['github_release.latest']('ramensoftware/windhawk', fallback='1.7.3', prerelease=True) %}
{%- set windhawk_path = 'C:/opt/windhawk' %}
{%- set windhawk_tmp = 'C:/opt/cozy/cache/windhawk-install.exe' %}

windhawk_installer:
  file.managed:
    - name: {{ windhawk_tmp }}
    - source: https://github.com/ramensoftware/windhawk/releases/download/{{ windhawk_version }}/windhawk_setup_offline.exe
    - skip_verify: True
    - mkdirs: True

windhawk_install:
  cmd.run:
    - name: >
        & "C:/opt/cozy/cache/windhawk-install.exe" /S /AUTO_UPDATE /PORTABLE /D={{ windhawk_path }}
    - shell: powershell
    - require:
      - file: windhawk_installer

windhawk_env:
  environ.setenv:
    - name: WINDHAWK_UI_PATH
    - value: {{ windhawk_path }}
    - update_minion: True
    - permanent: True

include:
  - windows.paths
