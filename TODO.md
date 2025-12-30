# cozy-salt TODO - Active Work

**Status:** Production Ready | **Last Updated:** 2025-12-30

## Completed (2025-12-30)

✅ **P0+P1 Consolidation** - Code bloat reduction (150+ lines eliminated)
✅ **P2 Linux** - Capability-based package organization (Linux)
✅ **P2 Windows** - Role-based package organization (Windows)
✅ **CRIT-001** - Removed auto_accept security vulnerability
✅ **CRIT-003** - Standardized base image to ubuntu:24.04
✅ **HIGH-005** - Removed duplicate healthcheck definitions
✅ **HIGH-003** - SSH Hardening Template Consolidation (90% duplication eliminated)
✅ **Infrastructure** - Fixed minion key mounting (removed .pem artifacts)

---

## Pending Work (in Priority Order)

### HIGH-002: Add YAML Anchors to docker-compose.yaml
**Impact:** ~30 lines saved, cleaner minion service definitions
**Effort:** 1 day
**Status:** Not started

Create YAML anchors for:
- Common minion config (volumes, environment, healthcheck)
- Apply to salt-minion-ubuntu and salt-minion-rhel

### HIGH-001: Consolidate Dockerfiles with Multi-Stage Build
**Impact:** ~50 lines saved, easier maintenance
**Effort:** 2-3 days
**Status:** Not started

- Create Dockerfile with multi-stage structure (salt-base → salt-master, salt-minion-deb, salt-minion-rpm)
- Update docker-compose.yaml to use `target:` parameter
- Remove old Dockerfile.linux-master and Dockerfile.ubuntu-minion

### HIGH-004: Extract Git Env Var Logic to Reusable Module
**Impact:** ~40 lines saved (Linux + Windows duplication)
**Effort:** 1 day
**Status:** Not started

Create `srv/salt/common/git_env.sls` with platform-specific implementations

### MED-001: Refactor dotfiles.sls to Remove Platform Conditionals
**Impact:** Cleaner architecture, removes platform logic from common states
**Effort:** Medium
**Status:** Not started

Use Jinja macros instead of conditional blocks

### MED-002: Refactor NVM States to Use Common Module
**Impact:** ~25 lines saved
**Effort:** Medium
**Status:** Not started

Extract common orchestration logic from windows/nvm.sls and linux/nvm.sls

### MED-003: Move WSL Detection Logic to Dedicated State Tree
**Impact:** Cleaner Linux states, dedicated WSL handling
**Effort:** Medium
**Status:** Not started

Create `srv/salt/wsl/` directory with WSL-specific configurations

### LOW-001: Implement Host-Specific Package Filtering
**Impact:** Dynamic package selection (deck vs desktop scenarios)
**Effort:** Medium
**Status:** Not started
**User Decision Needed:** Define host type taxonomy

### LOW-002: Add Pre-Commit Hooks
**Impact:** Automated linting before commits
**Effort:** Simple
**Status:** Not started

Add yamllint, shellcheck, PSScriptAnalyzer hooks

### LOW-003: Document Architecture Decisions
**Impact:** Knowledge capture
**Effort:** Simple
**Status:** Not started

Create ADRs for package selection, file structure, security defaults

---

## Summary

- **Completed:** 8 major tasks (30+ hours)
- **Remaining:** 9 tasks (8-10 days estimated)
- **Recommended Next:** HIGH-002 (YAML anchors) → HIGH-001 (Dockerfile consolidation)
