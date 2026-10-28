{%- set _pinned = salt['pillar.get']('versions:vibeshine:version', '') %}
{%- set vibeshine_version = _pinned or salt['github_release.latest']('Nonary/vibeshine', fallback='1.16.0-stable.3', prerelease=True) %}
{%- set vibeshine_assets = salt['github_release.assets']('Nonary/vibeshine', tag=vibeshine_version, prerelease=True) %}
{%- set _vibeshine_candidates = [] %}
{%- for a in vibeshine_assets %}
  {%- if a.name.endswith('.exe') %}
    {%- do _vibeshine_candidates.append(a) %}
  {%- endif %}
{%- endfor %}
{%- set vibeshine_source = _vibeshine_candidates[0].browser_download_url if _vibeshine_candidates else none %}
{%- set vibeshine_path = 'C:/opt/vibeshine' %}
{%- set vibeshine_tmp = 'C:/opt/cozy/cache/vibeshine-install.exe' %}

vibeshine_directory:
  file.directory:
    - name: {{ vibeshine_path }}
    - makedirs: True

vibeshine_download:
  file.managed:
    - name: {{ vibeshine_tmp }}
    - source: {{ vibeshine_source }}
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
