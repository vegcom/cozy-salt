# Common Git Environment Variables Module
# Exports GIT_NAME and GIT_EMAIL from global git config
# Platform-specific implementations:
# - Linux: Deploy shell script to /etc/profile.d (sourced on shell init)
# - Windows: Currently unsupported
{% if grains['os_family'] == 'Debian' or grains['os_family'] == 'RedHat' or grains['os_family'] == 'Arch' %}
# Linux/Unix: Deploy shell script to /etc/profile.d
git_env_vars_profile:
  file.managed:
    - name: /etc/profile.d/git-env.sh
    - source: salt://linux/files/etc-profile.d/git-env.sh
    - mode: "0644"
{% endif %}
