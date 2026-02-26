{% set _pinned = salt['pillar.get']('versions:vibeshine:version', '') %}
{% set vibeshine_version = _pinned or salt['github_release.latest']('Nonary/vibeshine') %}
{% set vibeshine_path     = 'C:\\opt\\vibeshine' %}
{% set vibeshine_tmp      = '$env:TEMP\\vibeshine-install.exe' %}

vibeshine_directory:
  file.directory:
    - name: {{ vibeshine_path }}
    - makedirs: True

vibeshine_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri 'https://github.com/Nonary/vibeshine/releases/download/{{vibeshine_version}}/VibeshineSetup.exe' -OutFile {{ vibeshine_tmp }}"
    - require:
      - file: vibeshine_directory

vibeshine_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& \"{{ vibeshine_tmp }}\" /qn /norestart"
    - creates: {{ vibeshine_path }}\vibeshine.exe
    - require:
      - cmd: vibeshine_download
