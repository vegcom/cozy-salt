# cozy-salt

SaltStack IaC for Windows/Linux workstation provisioning. Master runs in Docker.

## Quick Start

```bash
# Start master
make up-master

# Test on Ubuntu container
make test-ubuntu

# Test on RHEL container
make test-rhel

# Enroll a new minion (Linux)
sudo python3 scripts/enrollment/install-minion.py \
  --master salt.example.com \
  --minion-id myhost \
  --roles workstation,developer
```

## Structure

```
srv/salt/          # Salt states (linux/, windows/, common/)
srv/pillar/        # Pillar data (config per minion)
provisioning/      # Files to deploy (configs, scripts, templates)
scripts/           # Enrollment, Docker entrypoints, utilities
```

## Testing

```bash
make help          # List all targets
make test          # Run all tests (ubuntu + rhel)
make test-ubuntu   # Ubuntu only
make test-rhel     # RHEL only
make test-windows  # Windows via Dockur (requires KVM)
```

## Enrollment

- **Linux**: `scripts/enrollment/install-minion.py`
- **Windows**: `scripts/enrollment/install-minion.ps1`
- **Windows (Dockur)**: See `scripts/enrollment/WINDOWS.md`

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the 3 rules and development workflow.
