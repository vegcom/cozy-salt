{%- set _pinned = salt['pillar.get']('versions:vibeshine:version', '') %}
{%- set vibeshine_version = _pinned or salt['github_release.latest']('Nonary/vibeshine',fallback='1.16.0-stable.3') %}
{%- set vibeshine_path = 'C:/opt/vibeshine' %}
{%- set vibeshine_tmp = 'C:/opt/cozy/cache/vibeshine-install.exe' %}

vibeshine_directory:
  file.directory:
    - name: {{ vibeshine_path }}
    - makedirs: True

vibeshine_download:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "Invoke-WebRequest -Uri 'https://github.com/Nonary/vibeshine/releases/download/v{{ vibeshine_version }}/VibeshineSetup-v{{ vibeshine_version }}.exe' -OutFile {{ vibeshine_tmp }}"
    - require:
      - file: vibeshine_directory

vibeshine_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& '{{ vibeshine_tmp }}' /qn /norestart"
    - require:
      - cmd: vibeshine_download
