# RHEL/CentOS/Fedora/Rocky package installation (Role-Aware)
# Uses yum/dnf for package management
# See provisioning/packages.sls for full package definitions

{% import_yaml 'packages.sls' as packages %}
{% from "_macros/dist-packages.sls" import role_aware_packages %}

include:
  - linux.docker
  - linux.gpu

{{ role_aware_packages('rhel') }}
