# Orchestration: highstate all Linux minions
# Called by master scheduler via state.orchestrate
# Run manually: salt-run state.orchestrate orch.highstate-linux

linux_highstate:
  salt.state:
    - tgt: 'G@os_family:Debian or G@os_family:Arch or G@os_family:RedHat'
    - tgt_type: compound
    - highstate: True
    - batch: '25%'
    - splay: 300
