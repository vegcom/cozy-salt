# Orchestration: updates linux minions
# Called by master scheduler via state.orchestrate
# Run manually: salt-run state.orchestrate orch.update-minion-linux

# Arch Linux - uses custom yay module for AUR support
arch_upgrade:
  salt.function:
    - tgt: 'G@os_family:Arch'
    - tgt_type: compound
    - name: yay.upgrade
    - kwarg:
        runas: cozy-salt-svc

# Debian/Ubuntu - uses salt pkg module
debian_upgrade:
  salt.function:
    - tgt: 'G@os_family:Debian'
    - tgt_type: compound
    - name: pkg.upgrade
