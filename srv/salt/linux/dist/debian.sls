# Debian/Ubuntu package installation (Role-Aware)
# Uses apt for package management
# See provisioning/packages.sls for full package definitions

{% import_yaml 'packages.sls' as packages %}
{% from "_macros/dist-packages.sls" import role_aware_packages %}

include:
  - linux.docker
  - linux.gpu

{{ role_aware_packages('ubuntu', docker_apt_require=True) }}
