# cozy-salt

```plain
   ╭────────────────────────────────────────╮
   │    cozy‑salt — a comfy little salt     │
   ╰────────────────────────────────────────╯
                   (^-^)
                          ✧
                         ✧ ✧     Q(-_-q)
                       ✧  ✧  ✧
                         ✧ ✧
                          ✧
           (づ｡◕‿‿◕｡)づ
```

SaltStack IaC for Windows/Linux workstation provisioning. Master runs in Docker.

## [outstanding folks who made it so](AUTHORS.md)

- Listed in [AUTHORS.md](AUTHORS.md)

## Quick Start

```bash
# Pull repo and submodules
git pull --recursive git@github.com:vegcom/cozy-salt.git
cd cozy-salt
```

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

```plain
srv/salt/          # Salt states (linux/, windows/, common/)
srv/pillar/        # Pillar data (config per minion)
provisioning/      # Files to deploy (configs, scripts, templates)
scripts/           # Enrollment, Docker entrypoints, utilities
```

## Networking

Create a macvlan network and bridge

```bash
# 10.0.0.0/24 is a standin
docker network create -d macvlan \
  --subnet=10.0.0.0/24 \
  --gateway=10.0.0.1 \
  -o parent=eth0 \
  frontend
```

```bash
# 10.0.0.254 is an unassigned IP
ip link delete frontend-shim
ip link add frontend-shim link eth0 type macvlan mode bridge
ip addr add 10.0.0.254/24 dev frontend-shim
ip link set frontend-shim up
```

## Pillar Configuration

**Hierarchy** (later levels override earlier):

1. **Global defaults**: `srv/pillar/linux/init.sls`, `srv/pillar/windows/init.sls`, `srv/pillar/dist/*.sls`
2. **Hardware classes**: `srv/pillar/class/` (e.g., `galileo.sls` for Steam Deck)
3. **Per-host overrides**: `srv/pillar/host/example.sls` (copy template, rename to hostname)
4. **User configurations**: `srv/pillar/users/` (individual user configs, see `demo.sls` template)
5. **Secrets**: `srv/pillar/secrets/init.sls` (gitignored, tokens/credentials)

**User Management**:

- **Global**: `srv/pillar/common/users.sls` - managed users list + shared GitHub tokens
- **Per-user**: `srv/pillar/users/{username}.sls` - individual user configs
  - Template: `srv/pillar/users/demo.sls`
  - Copy template and rename to username (e.g., `newuser.sls`)
  - Includes: groups, SSH keys, git config (email/name), personal tokens
  - Tokens merge with global tokens automatically

**Git Credentials**:

- Stored in `.git-credentials` with format: `https://username:token@github.com`
- Deployed per-user via `srv/salt/common/gitconfig.sls`
- `.gitconfig.local` auto-populated with `[user]` section if email/name in pillar
- See `srv/pillar/users/demo.sls` for structure

## Enrollment

`git submodule update --recursive --remote`

[vegcom/cozy-salt-enrollment.git](https://github.com/vegcom/cozy-salt-enrollment)

- **Linux**: `scripts/enrollment/install-minion.py`
  - [install-minion.py](scripts/enrollment/install-minion.py)
- **Windows**: `scripts/enrollment/install-minion.ps1`
  - [install-minion.ps1](scripts/enrollment/install-minion.ps1)
- **Windows (Dockur)**: See [scripts/enrollment/WINDOWS.md](scripts/enrollment/WINDOWS.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the **3 rules** and development workflow.
