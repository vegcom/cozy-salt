# Windows package installation
# Packages defined in provisioning/packages.sls
# TODO: fix per user prov on spinup -- ref https://github.com/Romanitho/Winget-Install/issues/2
# TODO: assess installer type flags to see if we can better force handling https://github.com/microsoft/winget-cli/issues/4702
{%- import_yaml 'packages.sls' as packages %}
# Only install for users with real profiles (ProfileList registry check)
{%- from '_macros/windows.sls' import get_winget_user, get_winget_path, get_users_with_profiles with context %}
{%- set users_with_profiles = get_users_with_profiles().split(',') | reject('equalto', '') | list %}
{#- Service user performs scope=machine always #}
{%- set service_user = salt['pillar.get']('service_user', {}) %}
{%- set svc_name = service_user.get('name', 'cozy-salt-svc') %}
{#- Find user with winget installed via macro and check #}
{%- set winget_user = get_winget_user() %}
{%- set winget_path = get_winget_path(winget_user) %}
{%- if not salt['file.file_exists'](winget_path) %}
  {%- set winget_path = salt['cmd.run']('@((Get-Item "C:\\Program Files\\WindowsApps\\Microsoft.DesktopAppInstaller*\\winget.exe").VersionInfo.FileName)[-1]', shell='powershell') %}
winget_path_fallback:
  test.nop:
    - name: winget path fallback to {{ winget_path }}, prior(invalid_path) {{ get_winget_path(winget_user) }}
{%- endif %}
{#- gate on file present #}
{%- if salt['file.file_exists'](winget_path) %}
{#- pwsh - from pillar #}
{%- set _pwsh_ver = salt['pillar.get']('_pinned_pwsh', salt['github_release.latest']('PowerShell/PowerShell', fallback='7.5.4')) %}
{%- set pwsh_url = 'https://github.com/PowerShell/PowerShell/releases/download/v' ~ _pwsh_ver ~ '/PowerShell-' ~ _pwsh_ver ~ '.msixbundle' %}

# PowerShell Modules (from powershell_gallery) - requires pwsh installed
{%- set all_pwsh_modules = packages.windows.get('pwsh_modules', []) %}
{%- if all_pwsh_modules %}
  {%- for module in all_pwsh_modules %}
pwsh_module_{{ module | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - shell: pwsh
    - name: >
        Remove-Module PackageManagement,PowerShellGet -Force -ErrorAction SilentlyContinue;
        Install-Module -Name {{ module }} -Scope AllUsers -AllowClobber -SkipPublisherCheck -Force -Repository PSGallery
    - onlyif: Get-Command pwsh -ErrorAction SilentlyContinue
  {%- endfor %}
{%- endif %}

chocolatey-install:
  chocolatey.bootstrapped

chocolatey-upgrade:
  cmd.run:
    - name: choco upgrade chocolatey
    - require:
      - chocolatey: chocolatey-install

# Enable Chocolatey features
{%- set choco_feature_list = pillar.get('choco_features', []) %}
{%- if choco_feature_list %}
  {%- for feature in choco_feature_list %}
choco_feature_{{ feature }}_enabled:
  cmd.run:
    - name: choco feature enable -n={{ feature }}
    - shell: cmd
    - success_retcodes:
      - 0
      - 2
    - require:
      - chocolatey: chocolatey-install
  {%- endfor %}
{%- endif %}

# Install Chocolatey packages
{%- if packages.windows.choco is defined %}
  {%- for pkg in packages.windows.choco %}
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  chocolatey.installed:
    - name: {{ pkg }}
    - require:
      - chocolatey: chocolatey-install
choco_{{ pkg | replace('.', '_') | replace('-', '_') }}_update:
  chocolatey.upgraded:
    - name: {{ pkg }}
    - unless:
      - chocolatey: choco_{{ pkg | replace('.', '_') | replace('-', '_') }}
  {%- endfor %}
{%- endif %}

# Winget bootstrap/repair
winget_bootstrap:
  cmd.run:
    - name:  Repair-WinGetPackageManager -AllUsers -IncludePrerelease -Force -Verbose
    - shell: powershell

# Winget features
winget_features_enable:
  cmd.run:
    - shell: powershell
    - name: winget configure --enable --include-prerelease

# Install Winget runtime packages, machine scope (run as user with winget)
{%- if packages.windows.winget.runtimes is defined %}
  {%- for category, pkgs in packages.windows.winget.runtimes.items() %}
    {%- for pkg in pkgs %}
winget_runtime_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    # - runas: {{ svc_name }}
    - shell: powershell
    - name: '&"{{ winget_path }}" install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --include-prerelease --exact --id {{ pkg }}'
    - unless: '&"{{ winget_path }}" list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    #  - onlyif: Test-Path '{{ winget_path }}'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}
{%- endif %}

# Install Winget packages by category, machine scope (run as user with winget)
# noscope list = packages that choke on --scope machine flag (360 noscope lol)
{%- set noscope_pkgs = packages.windows.winget.get('noscope', []) %}
{%- if packages.windows.winget.system is defined %}
  {%- for category, pkgs in packages.windows.winget.system.items() %}
    {%- for pkg in pkgs %}
winget_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
      {%- if pkg in noscope_pkgs %}
    - name: '&"{{ winget_path }}" install --accept-source-agreements --accept-package-agreements --disable-interactivity --include-prerelease --exact --id {{ pkg }}'
      {%- else %}
    - name: '&"{{ winget_path }}" install --scope machine --accept-source-agreements --accept-package-agreements --disable-interactivity --include-prerelease --exact --id {{ pkg }}'
      {%- endif %}
    # - runas: {{ svc_name }}
    - shell: powershell
    - unless: '&"{{ winget_path }}" list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    #  - onlyif: Test-Path '{{ winget_path }}'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}

# machine scope upgrade
winget_upgrade_machine:
  cmd.run:
    - name: '&"{{ winget_path }}" upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    # - runas: {{ svc_name }}
    #  - onlyif: Test-Path '{{ winget_path }}'
{%- endif %}

# Installs userland packages, user scope (each user's own winget)
# TODO: can support msi, exe, and msix with --installer-type
# https://learn.microsoft.com/en-us/windows/package-manager/winget/#:~:text=The%20winget%20tool%20supp
{%- if users_with_profiles is defined %}
{%- for user in users_with_profiles %}
{%- set user_winget = 'C:\\Users\\' ~ user ~ '\\AppData\\Local\\Microsoft\\WindowsApps\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\\winget.exe' %}
  {%- if salt['file.file_exists'](user_winget) %}
  {%- for category, pkgs in packages.windows.winget.userland.items() %}
    {%- for pkg in pkgs %}
winget_userland_{{ user | replace('.', '_') | replace('-', '_') }}_{{ pkg | replace('.', '_') | replace('-', '_') }}:
  cmd.run:
    - name: '{{ user_winget }} install --accept-source-agreements --accept-package-agreements --disable-interactivity --include-prerelease --exact --id {{ pkg }}'
    - runas: {{ user }}
    - shell: powershell
    - unless: '{{ user_winget }} list --exact --id {{ pkg }} | Select-String -Quiet -Pattern ''{{ pkg }}'''
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
    - timeout: 300
    {%- endfor %}
  {%- endfor %}
  {%- endif %}

# Per user winget upgrades, use cmd to upgrade pwsh
winget_upgrade_{{ user }}:
  cmd.run:
    - name: '{{ user_winget }} upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'
    - runas: {{ user }}
    - onlyif: '& ''{{ user_winget }}'' --version 2>&1 | Select-String -Quiet "v\d"'
  {%- else %}
winget_userland_skipped_profile:
  test.nop:
    - name: Winget can notinstall userland  packages without users with profiles
{%- endfor %}
{%- else %}
winget_userland_skipped_winget:
  test.nop:
    - name: Winget not found at path {{ user_winget }}
{%- endif %}
  {%- else %}
winget_skipped:
  test.nop:
    - name: winget path could not be solved for
  {%- endif %}
