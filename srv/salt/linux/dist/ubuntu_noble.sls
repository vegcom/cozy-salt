# Ubuntu Noble / Kali / WSL docker repo configuration
# Fixes broken repos created by get.docker.com on Kali/WSL
# Kali/WSL get wrong repos that 404 — replace with Ubuntu noble (officially supported)

{% set is_kali = grains.get('os', '') == 'Kali' %}
{% set is_wsl = grains.get('kernel_release', '').find('WSL') != -1 %}

{% if is_kali or is_wsl %}

# Remove broken Docker repos created by get.docker.com
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

ubuntu_noble_noop:
  test.nop:
    - name: Ubuntu Noble docker repo config not needed on this system

{% endif %}
