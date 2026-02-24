# Orchestration: highstate all Windows minions
# Called by master scheduler via state.orchestrate
# Run manually: salt-run state.orchestrate orch.highstate-windows

windows_highstate:
  salt.state:
    - tgt: 'G@os_family:Windows'
    - tgt_type: compound
    - highstate: True
    - batch: '25%'
    - splay: 600
