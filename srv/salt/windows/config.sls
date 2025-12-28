# Windows configuration
# User setup, environment, and system configuration

# Detect if WSL is available and set grain for future targeting
detect_wsl:
  cmd.run:
    - name: powershell -NoProfile -Command "if (Get-Command wsl -ErrorAction SilentlyContinue) { 'true' } else { 'false' }"
    - stateful: False
  grains.present:
    - name: is_wsl
    - value: True
    - require:
      - cmd: detect_wsl

# Bootstrap script deployment (Docker context setup)
deploy_configure_docker_wsl_context:
  file.managed:
    - name: C:\opt\cozy\configure-docker-wsl-context.ps1
    - source: salt://windows/files/opt-cozy/configure-docker-wsl-context.ps1
    - makedirs: True

run_configure_docker_wsl_context:
  cmd.run:
    - name: powershell -ExecutionPolicy Bypass -File C:\opt\cozy\configure-docker-wsl-context.ps1
    - creates: C:\opt\cozy\.done.flag
    - require:
      - file: deploy_configure_docker_wsl_context

# Deploy hardened SSH configuration
sshd_hardening_config:
  file.managed:
    - name: C:\ProgramData\ssh\sshd_config.d\99-hardening.conf
    - source: salt://windows/files/ProgramData/ssh/sshd_config.d/99-hardening.conf
    - makedirs: True

# Export git user config as environment variables for vim
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
    - shell: powershell
    - onlyif: git config --global user.name
