# Configures salt-minion returner (cozy_notify desktop toasts)
# Master-side job cache handled via master_job_cache: mongo in master conf

include:
  - linux.returners
  - windows.returners
