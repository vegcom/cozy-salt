# Docker installation and repository configuration
# Handles Debian, Ubuntu, Kali, WSL, and RHEL systems
# Auto-detects system type and configures correct Docker repo

{% set os_family = grains['os_family'] %}
{% set is_kali = grains.get('os', '') == 'Kali' %}
{% set is_wsl = salt['file.file_exists']('/proc/version') and 'microsoft' in salt['cmd.run']('cat /proc/version 2>/dev/null || echo ""', python_shell=True).lower() %}

# Install Docker using official installer script (handles repo setup and GPG keys automatically)
# Works on Debian, Ubuntu, CentOS, RHEL, Fedora via get.docker.com
docker_install:
  cmd.run:
    - name: curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sh /tmp/get-docker.sh
    - creates: /usr/bin/docker

{% if os_family == 'Debian' %}
{% if is_kali or is_wsl %}
# Remove broken Docker repos created by get.docker.com
# Kali/WSL get wrong repos that 404
docker_repo_cleanup:
  cmd.run:
    - name: rm -f /etc/apt/sources.list.d/docker*.list /etc/apt/sources.list.d/archive_uri-*.list 2>/dev/null || true
    - require:
      - cmd: docker_install

# Create correct Docker repo using Ubuntu noble (officially supported)
docker_repo_fix:
  file.managed:
    - name: /etc/apt/sources.list.d/docker.list
    - contents: |
        # Docker repo for Kali/WSL - using Ubuntu noble (official supported)
        deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable
    - require:
      - cmd: docker_repo_cleanup

docker_apt_update:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - file: docker_repo_fix
{% else %}
# Native Debian - just update after docker install
docker_apt_update:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - cmd: docker_install
{% endif %}
{% endif %}
