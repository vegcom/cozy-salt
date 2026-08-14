{%- set _pinned = salt['pillar.get']('versions:vibeshine:version', '') %}
{%- set vibeshine_version = _pinned or salt['github_release.latest']('Nonary/vibeshine',fallback='1.16.0-stable.3', prerelease=True) %}
{%- set vibeshine_path = 'C:/opt/vibeshine' %}
{%- set vibeshine_tmp = 'C:/opt/cozy/cache/vibeshine-install.exe' %}

vibeshine_directory:
  file.directory:
    - name: {{ vibeshine_path }}
    - makedirs: True

vibeshine_download:
  file.managed:
    - name: {{ vibeshine_tmp }}
    - source: https://github.com/Nonary/vibeshine/releases/download/{{ vibeshine_version }}/VibeshineSetup-{{ vibeshine_version }}.exe
    - skip_verify: True
    - mkdirs: True

vibeshine_install:
  cmd.run:
    - name: >
        pwsh -NoLogo -Command
        "& '{{ vibeshine_tmp }}' /qn /norestart"
    - require:
      - file: vibeshine_download

include:
  - windows.paths
