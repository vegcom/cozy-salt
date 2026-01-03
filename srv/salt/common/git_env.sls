# Common Git Environment Variables Module
# Exports GIT_NAME and GIT_EMAIL from global git config
# Platform-specific implementations:
# - Linux: Deploy shell script to /etc/profile.d (sourced on shell init)
# - Windows: Set User environment variables via PowerShell (persistent)

{% if grains['os_family'] == 'Debian' or grains['os_family'] == 'RedHat' %}

# Linux/Unix: Deploy shell script to /etc/profile.d
git_env_vars_profile:
  file.managed:
    - name: /etc/profile.d/git-env.sh
    - source: salt://linux/files/etc-profile.d/git-env.sh
    - mode: 644

{% elif grains['os_family'] == 'Windows' %}

# Windows: Set environment variables via PowerShell
git_env_vars_windows:
  cmd.run:
    - name: |
        $name = git config --global user.name
        $email = git config --global user.email
        if ($name -and $email) {
          [System.Environment]::SetEnvironmentVariable('GIT_NAME', $name, 'User')
          [System.Environment]::SetEnvironmentVariable('GIT_EMAIL', $email, 'User')
          Write-Host "Set GIT_NAME=$name and GIT_EMAIL=$email"
        } else {
          Write-Host "Git user not configured yet, skipping"
        }
    - shell: pwsh
    - onlyif: git config --global user.name

{% endif %}
