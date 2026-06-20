# RHEL/CentOS/Fedora/Rocky package installation (Role-Aware)
# Uses yum/dnf for package management
# See provisioning/packages.sls for full package definitions

{%- if grains['os_family'] == 'RedHat' %}
{%- import_yaml 'packages.sls' as packages %}
{%- from "_macros/dist-packages.sls" import role_aware_packages %}

include:
  - linux.docker
  - linux.gpu

{{ role_aware_packages('rhel') }}

{%- else %}

skip_rhel_packages:
  test.nop:
    - name: Skipping on non-RHEL system

{%- endif %}
