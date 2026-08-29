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

> [!NOTE]
> [AI-generated docs available on DeepWiki](https://deepwiki.com/vegcom/cozy-salt) — auto-generated, may drift.
>
> [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/vegcom/cozy-salt)

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
```

[enroll new devices](#enrollment)

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
# 10.0.0.0/16 is a standin
# Dictates ingress, make sure every host that needs on is includd in your subnet
docker network create -d macvlan \
  --subnet=10.0.0.0/16 \
  --gateway=10.0.0.1 \
  -o parent=eth0 \
  frontend
```

```bash
# 10.0.0.254 is an unassigned IP
ip link delete frontend-shim
ip link add frontend-shim link eth0 type macvlan mode bridge
ip addr add 10.0.0.254/16 dev frontend-shim
ip link set frontend-shim up
```

```bash
# 10.0.0.220 is the default salt master IP
ip route add 10.0.0.220/32 dev frontend-shim
```

## Pillar Configuration

**Hierarchy** (later levels override earlier):

1. **Global defaults**: `srv/pillar/linux/init.sls`, `srv/pillar/windows/init.sls`, `srv/pillar/dist/*.sls`
2. **Hardware classes**: `srv/pillar/hardware/` (e.g., `galileo.sls` for Steam Deck)
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

OneDir install is proper install
[salt/install-guide](https://docs.saltproject.io/salt/install-guide)

```pwsh
# Windows option
scripts/enroll.ps1
```

```bash
# Linux option
scripts/enroll.sh
```

### Theme and customization

> [!NOTE]
> [Themeing and customization](https://github.com/vegcom/Twilite-Theme) —
> leverages **Twilite**: _A theme for those who love a cute purple hue._

## Little wins

- [Arch onedir fix](https://github.com/saltstack/salt-bootstrap/pull/2101)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the **3 rules** and development workflow.

---

## Thanks ♡

- <https://github.com/saltstack/salt>
- <https://github.com/erwindon/SaltGUI>
