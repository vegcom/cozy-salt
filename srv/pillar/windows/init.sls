#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

host:
  capabilities:
    sshd: {{ True if not salt['grains.get']('virtual', '') in ['docker', 'container', 'lxc'] }}

include:
  - windows.choco
  - windows.detected_user
  - windows.paths
  - windows.schedule
  - windows.tasks
  - windows.versions
