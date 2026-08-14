schedule:
  windows_health_check:
    function: cmd.script
    args:
      - salt://windows/files/opt-cozy-bin/health-check.ps1
    kwargs:
      shell: powershell
    days: 7
    enabled: True
    return_job: True
