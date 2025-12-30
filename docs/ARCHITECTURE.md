# Architecture Decision Records (ADRs)

This document captures key architectural decisions made in cozy-salt.

## ADR-001: Capability-Based Package Organization (Linux)

**Status:** Approved (2025-12-30)

**Context:**
Managing package dependencies across multiple Linux distributions (Ubuntu, RHEL/Rocky) with different package names and availability.

**Decision:**
Organize Linux packages by capability (core_utils, monitoring, shell, build, networking, etc.) rather than by distribution or role. This allows:
- Platform-independent capability declarations
- Easy discovery of available packages
- Clear dependencies between capability groups

**Consequences:**
- Packages are categorized by function, not distribution
- Package names are aliased per distribution in packages.sls
- New capabilities require adding to both package list and platform mappings
- Clear separation between provisioning logic and package declarations

**Validation:**
- Ubuntu (apt-based) packages: 100% installation success
- RHEL (dnf-based) packages: 100% installation success (EPEL enabled for extra packages)
- All test suites pass with no missing packages

---

## ADR-002: Role-Based Package Selection (Windows)

**Status:** Approved (2025-12-30)

**Context:**
Windows systems have varied use cases (minimal CLI, desktop dev, gaming, enterprise). Need dynamic package selection based on system type.

**Decision:**
Define predefined roles (minimal, base, dev, gaming, full) with explicit package lists. Pillars can specify a system's role, making installation predictable and minimal by default.

**Consequences:**
- Roles are immutable/predefined (not customizable per-host initially)
- Different roles share common base packages
- System role defined in pillar, not auto-detected
- Enables ~90% package reduction on minimal installs

**Validation:**
- Minimal role: ~15-20 packages (91% reduction from default 174)
- All roles install successfully via Chocolatey/Winget

---

## ADR-003: Consolidated SSH Hardening Template

**Status:** Approved (2025-12-30)

**Context:**
Three platforms (Linux, WSL, Windows) had duplicate SSH hardening configurations with platform-specific differences.

**Decision:**
Create single `_templates/sshd_hardening.conf.jinja` template using Jinja2 conditionals to handle platform differences:
- Windows: Uses `KbdInteractiveAuthentication` (PAM-style auth)
- Unix/Linux: Uses `ChallengeResponseAuthentication`
- WSL: Configures port 2222 (Windows port collision workaround)

**Consequences:**
- Single source of truth for SSH security policy
- Platform conditionals in template, not states
- Easier to update hardening rules consistently
- ~40 lines of duplication eliminated

**Validation:**
- SSH template renders correctly on all platforms
- Hardening rules applied successfully
- No SSH errors during state execution

---

## ADR-004: File Roots Separation

**Status:** Approved (2025-12-30)

**Context:**
Salt states and provisioning files stored in separate directories, but need to be accessible as salt:// URIs.

**Decision:**
Configure Salt master with two file_roots:
1. `/srv/salt` - Salt state files (.sls)
2. `/srv/provisioning` - Provisioning artifacts (scripts, configs, packages)

Both directories are sibling roots, allowing `salt://linux/files/...` to resolve from `/srv/provisioning/linux/files/...`.

**Consequences:**
- Provisioning files mounted separately from states
- States reference `salt://platform/files/...` (not `salt://provisioning/...`)
- File mounts must be configured in docker-compose.yaml
- Clear separation between Salt logic and deployment artifacts

**Validation:**
- File references resolve correctly
- Both state and provisioning files accessible
- No conflicts between salt:// paths

---

## ADR-005: Multi-Stage Dockerfile Consolidation

**Status:** Approved (2025-12-30)

**Context:**
Three separate Dockerfiles (master, ubuntu-minion, rhel-minion) with duplicated base setup logic.

**Decision:**
Create single multi-stage Dockerfile with 5 build targets:
- `salt-base-deb` - Common Debian/Ubuntu base
- `salt-master` - Built from salt-base-deb
- `salt-minion-deb` - Built from salt-base-deb (Ubuntu)
- `salt-base-rpm` - Common RHEL/Rocky base
- `salt-minion-rpm` - Built from salt-base-rpm (Rocky)

Docker-compose.yaml references specific targets via `target:` parameter.

**Consequences:**
- Single Dockerfile source of truth
- Base layers reused (faster builds, less disk)
- Easier maintenance (one place to update Salt version)
- ~50 lines consolidated

**Validation:**
- All build targets compile successfully
- Services start and run correctly
- No layer duplication

---

## ADR-006: Jinja Macros for Cross-Platform Dotfiles

**Status:** Approved (2025-12-30)

**Context:**
Dotfile deployment states (gitconfig, vim) repeated platform-specific path logic (/ vs \ separators).

**Decision:**
Create `_dotfiles_macros.sls` with reusable Jinja2 macros:
- `get_user_home(username)` - Returns platform-appropriate path
- `dotfile_path(home, name)` - Constructs platform-aware paths
- `deploy_file()`, `deploy_directory()`, `deploy_symlink()` - Handle platform differences

States import macros and call them instead of using conditional blocks.

**Consequences:**
- Platform logic centralized in macros
- States are cleaner and more readable
- New dotfiles can reuse macros
- ~50 lines of conditionals eliminated

**Validation:**
- Macros render correctly on both platforms
- Dotfiles deploy successfully
- No path separator errors

---

## ADR-007: Common Module Orchestration for NPM Packages

**Status:** Approved (2025-12-30)

**Context:**
Linux NVM and Windows NVM states both iterate through npm_global packages with minor platform differences (shell, environment).

**Decision:**
Extract npm package installation to `common/nvm.sls`. Platform-specific NVM installation (curl vs nvm-windows) stays in linux/nvm.sls and windows/nvm.sls, but both include common.nvm for npm packages.

**Consequences:**
- Single npm package installation logic
- Platform-specific NVM setup preserved
- Adding npm packages: update packages.sls once
- Scales to new platforms easily

**Validation:**
- All npm packages install successfully
- No duplicate package installation loops
- Common module works on both platforms

---

## ADR-008: Dedicated WSL State Tree

**Status:** Approved (2025-12-30)

**Context:**
Windows configuration states included WSL detection and Docker context setup, mixing concerns.

**Decision:**
Create dedicated `srv/salt/wsl/` directory with init.sls containing:
- WSL availability detection (grains)
- Docker context configuration

Windows config.sls includes wsl module instead of inline logic.

**Consequences:**
- WSL logic isolated and reusable
- Easier to extend WSL-specific features
- Windows config simpler (smaller file)
- Clear separation of concerns

**Validation:**
- WSL detection works correctly
- Docker context setup succeeds
- States execute without errors

---

## ADR-009: Security: Pre-Shared Minion Keys (No Auto-Accept)

**Status:** Approved (2025-12-30)

**Context:**
Auto-accepting minion keys in Salt master poses security risk in production (environment variables could accidentally enable auto-accept).

**Decision:**
Use pre-shared public keys (.pub files) in minions_pre directory. Private keys (.pem) remain on minions and are NOT mounted to master.

Mount only individual .pub files with correct minion ID names to minions_pre directory.

**Consequences:**
- No auto-accept environment variable in master
- Pre-shared keys require key exchange before testing
- Clean salt-key output (no artifact keys)
- More secure (matches production practice)

**Validation:**
- Master correctly lists only valid minion keys
- No .pem file artifacts in minions_pre
- Minions authenticate successfully

---

## ADR-010: Container Detection Pattern

**Status:** Approved (2025-12-30)

**Context:**
Some states (SSH service, DNS configuration) don't apply in container environments. Need reliable container detection.

**Decision:**
Detect containers by checking for well-known container markers:
- `/.dockerenv` (Docker)
- `/run/.containerenv` (Podman/Kubernetes)

Use pattern: `{% set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}`

Conditionally skip incompatible states when `is_container == True`.

**Consequences:**
- Works across Docker, Podman, Kubernetes
- Allows same states to run on bare metal and containers
- Container services naturally skip (SSH, systemd, etc.)
- No forced service failures in containers

**Validation:**
- Container detection works in Docker/Podman
- Services skip correctly in containers
- All container tests pass

---

## Summary

These ADRs document the major architectural decisions in cozy-salt. They represent choices that significantly impact:
- Maintainability (consolidation, DRY principle)
- Security (pre-shared keys, no auto-accept)
- Cross-platform support (templates, macros)
- Operational ease (role-based packages, container support)

Each decision includes validation evidence from actual test runs.
