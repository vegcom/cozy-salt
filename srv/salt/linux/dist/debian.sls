# Debian/Ubuntu package installation (Role-Aware)
# Uses apt for package management
# See provisioning/packages.sls for full package definitions

{%- if grains['os_family'] == 'Debian' %}
{%- from '_macros/packages.sls' import get_packages %}
{%- set packages = get_packages() | load_json %}
{%- from "_macros/dist-packages.sls" import role_aware_packages %}
{%- set is_kali = grains.get('os', '') == 'Kali' %}
{%- set is_wsl = grains.get('kernel_release', '').find('WSL') != -1 %}

include:
  - linux.docker
  - linux.dist.ubuntu_noble
  - linux.gpu

{%- if not (is_kali or is_wsl) %}
# Native Debian: update apt after docker install (get.docker.com adds correct repo)
docker_apt_update:
  cmd.run:
    - name: apt-get update --allow-releaseinfo-change
    - require:
      - cmd: docker_install
{%- endif %}

apt_allow_unauthenticated:
  file.managed:
    - name: /etc/apt/apt.conf.d/99-allow-unauthenticated
    - contents: |
        APT::Get::AllowUnauthenticated "true";
    - mode: "0644"

{{ role_aware_packages('ubuntu', docker_apt_require=True) }}

{%- else %}
apt_allow_unauthenticated:
  test.nop:
    - name: Skipping APT config on non-Debian system
{%- endif %}
