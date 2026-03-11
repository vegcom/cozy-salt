# Debian/Ubuntu package installation (Role-Aware)
# Uses apt for package management
# See provisioning/packages.sls for full package definitions

{% if grains['os_family'] == 'Debian' %}
{% import_yaml 'packages.sls' as packages %}
{% from "_macros/dist-packages.sls" import role_aware_packages %}

include:
  - linux.docker
  - linux.gpu

apt_allow_unauthenticated:
  file.managed:
    - name: /etc/apt/apt.conf.d/99-allow-unauthenticated
    - contents: |
        APT::Get::AllowUnauthenticated "true";
    - mode: "0644"

{{ role_aware_packages('ubuntu', docker_apt_require=True) }}

{% else %}
apt_allow_unauthenticated:
  test.nop:
    - name: Skipping APT config on non-Debian system
{% endif %}
