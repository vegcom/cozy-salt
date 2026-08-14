#!jinja|yaml
# Windows Pillar Data
# Configuration values for Windows minions

include:
  - windows.choco
  - windows.detected_user
  - windows.paths
  - windows.schedule
  - windows.tasks
  - windows.versions
