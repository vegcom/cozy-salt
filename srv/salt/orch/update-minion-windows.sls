# Orchestration: updates windows minions
# Called by master scheduler via state.orchestrate
# Run manually: salt-run state.orchestrate orch.update-minion-windows

windows_upgrade:
  salt.state:
    - tgt: 'G@os_family:Windows'
    - tgt_type: compound
    - sls:
      - windows.upgrade
