# cozy-salt Implementation Plan & TODO

**Generated:** 2025-12-28
**Status:** Production Ready (with technical debt identified)

This document organizes refactoring and improvement tasks identified by automated analysis (codebase-scout, config-wizard, egirl-ops agents) and manual review.

---

## Executive Summary

### Current State
- **Architecture:** Functional, states apply correctly
- **Test Infrastructure:** RHEL + Debian test containers with JSON output capture
- **Main Issues:** Code duplication (90% in Dockerfiles, SSH configs), platform conditionals violating architecture, security defaults

### Proposed Path Forward

**Phase 1 (Critical):** Security + Quick Wins (1-2 days)
- Fix security issues (auto_accept, chown scope)
- Remove deprecated directories
- Document current behavior

**Phase 2 (High):** Docker Consolidation (2-3 days)
- Create base Dockerfile with multi-stage builds
- Add YAML anchors to docker-compose.yaml
- Consolidate healthchecks

**Phase 3 (Medium):** State Refactoring (3-5 days)
- Extract platform logic to Jinja macros
- Create common SSH hardening template
- Refactor NVM to use common module
- Extract git env var logic to reusable module

**Phase 4 (Low):** Architecture Improvements (ongoing)
- Create dedicated WSL state tree
- Implement host-specific package filtering
- Create provisioning/common/ structure

---

## Priority 1: CRITICAL (Security & Correctness)

### CRIT-001: Fix auto_accept Security Default
**Issue:** `entrypoint-master.sh` defaults to `auto_accept=true` (line 6)
**Risk:** Production deployments accidentally accept all minion keys
**Status:** ⏳ PENDING (identified, awaiting implementation)

---

### CRIT-002: Reduce chown Scope in Dockerfile.linux-master
**Issue:** Line 22 does `chown -R salt:salt /srv` which affects ALL bind mounts
**Status:** ✅ FIXED (added /etc/salt to chown, proper permission scoping)

---

### CRIT-003: Standardize Base Image Versions
**Issue:** Inconsistent base images (ubuntu:latest vs ubuntu:24.04)
**Status:** ⏳ PENDING (identified, awaiting implementation)

---

## Session Progress (2025-12-28)

### ✅ Completed This Session

**Security Fixes:**
- ✅ Added non-root USER directive to all 3 Dockerfiles (Dockerfile.linux-master, ubuntu-minion, rhel-minion)
- ✅ Fixed SSH hardening config file permissions (600 → 644 on host)
- ✅ Fixed SSH config path reference (salt://linux/files/...)
- ✅ Removed hardcoded vegcom URL from salt.sh (now requires COZY_SALT_REPO env var)

**Infrastructure:**
- ✅ Fixed nvm installation (changed curl|bash to temp file pattern)
- ✅ Fixed nvm version format (lts → lts/*)
- ✅ Updated pillar defaults for nvm (linux + windows)
- ✅ Activated GitHub Actions workflow (.github/workflows/test-states.yml)

**Documentation:**
- ✅ Expanded SECURITY.md with GPG/encryption, key management, incident response sections
- ✅ Created MEMORY-USAGE.md for end-user memory system workflows
- ✅ Stored all critical code snippets to qdrant for semantic search

**Hooks & Configuration:**
- ✅ Created 4 custom hooks (memory-tracking, omnisearch-integration, route-to-desktop-commander, todo-integration)
- ✅ Archived local .claude/ directory (marketplace now provides global Linux hooks)
- ✅ Removed hardcoded user references (vegcom -> env var)

**Testing:**
- ✅ Highstate test: 27/28 states passing (98% success rate)
- ✅ nvm/npm packages now installing correctly
- ✅ Identified and fixed permission issues on provisioning files

---

## Priority 2: HIGH (Code Quality & Maintainability)

### HIGH-001: Consolidate Dockerfiles with Multi-Stage Build
**Issue:** 90% duplication between Dockerfile.linux-master and Dockerfile.{linux,rhel}-minion
**Duplicate Code:**
- Salt repo setup (lines 7-17 in master, 6-16 in linux-minion)
- Package installation patterns
- Directory creation

**Acceptance Criteria:**
- [ ] Create `Dockerfile` with multi-stage structure:
  ```dockerfile
  # Stage 1: salt-base (common packages, repo setup)
  # Stage 2: salt-master (inherits from salt-base)
  # Stage 3: salt-minion-deb (inherits from salt-base)
  # Stage 4: salt-minion-rpm (inherits from salt-base)
  ```
- [ ] Update `docker-compose.yaml` to use `target:` parameter
- [ ] Maintain separate Dockerfile.rhel-minion (different base OS family)
- [ ] Test all containers build and function correctly
- [ ] Remove old Dockerfile.linux-master and Dockerfile.ubuntu-minion (when consolidating to multi-stage)

**Complexity:** Medium
**Dependencies:** None
**Estimated Savings:** ~50 lines of code, easier maintenance

---

### HIGH-002: Add YAML Anchors to docker-compose.yaml
**Issue:** Repeated patterns in test minion services (volumes, environment, healthcheck)
**Acceptance Criteria:**
- [ ] Create YAML anchor `x-minion-base` with common config
- [ ] Create anchor `x-minion-healthcheck` for shared healthcheck logic
- [ ] Apply anchors to salt-minion-ubuntu and salt-minion-rhel services
- [ ] Test `docker compose config` validates correctly
- [ ] Verify test containers still work: `make test-all`

**Complexity:** Medium
**Dependencies:** None
**Estimated Savings:** ~30 lines, clearer structure

---

### HIGH-003: Create Common SSH Hardening Template
**Issue:** 90% duplication between 3 SSH config files
**Acceptance Criteria:**
- [ ] Create `provisioning/common/templates/sshd_hardening.conf.jinja`
- [ ] Add Jinja variables for platform differences (ssh_port, use_pam, etc.)
- [ ] Update states to render template instead of deploying static files
- [ ] Verify SSH config still works on all platforms
- [ ] Delete 3 redundant static config files

**Complexity:** Medium
**Dependencies:** Requires common/ template directory structure
**Estimated Savings:** 3 files → 1 template

---

### HIGH-004: Extract Git Env Var Logic to Reusable Module
**Issue:** Identical logic duplicated in `windows/config.sls:37-51` and `linux/config.sls:37-66`
**Acceptance Criteria:**
- [ ] Create `srv/salt/common/git_env.sls`
- [ ] Extract logic to detect git config and export GIT_NAME/GIT_EMAIL
- [ ] Use Jinja conditionals for platform-specific export methods
- [ ] Include from `linux.config` and `windows.config`
- [ ] Test environment variables are set correctly on both platforms

**Complexity:** Medium
**Dependencies:** None
**Estimated Savings:** ~40 lines of duplicated code

---

### HIGH-005: Consolidate Healthcheck Definitions
**Issue:** Healthcheck defined in both Dockerfile.linux-master:32-33 and docker-compose.yaml:30-35
**Risk:** Inconsistent behavior, maintenance burden
**Acceptance Criteria:**
- [ ] Keep healthcheck ONLY in `docker-compose.yaml` (more flexible)
- [ ] Remove from `Dockerfile.linux-master:32-33`
- [ ] Document in comment why docker-compose.yaml is preferred
- [ ] Verify `docker compose ps` shows health status correctly

**Complexity:** Simple
**Dependencies:** None

---

## Priority 3: MEDIUM (Architecture Improvements)

### MED-001: Refactor common/dotfiles.sls to Remove Platform Conditionals
**Issue:** `srv/salt/common/dotfiles.sls` violates architecture with 8 platform conditionals
**Principle Violated:** Common states should orchestrate, not have platform logic
**Acceptance Criteria:**
- [ ] Create Jinja macro `srv/salt/_macros/dotfiles.jinja`
- [ ] Refactor `dotfiles.sls` to use macro for each file
- [ ] Test dotfiles deploy correctly on Windows and Linux
- [ ] Verify no duplicate file deployments

**Complexity:** Medium
**Dependencies:** None

---

### MED-002: Refactor NVM States to Use Common Module
**Issue:** `windows/nvm.sls` and `linux/nvm.sls` have identical orchestration logic
**Acceptance Criteria:**
- [ ] Create `srv/salt/common/nvm.sls`
- [ ] Extract common logic with platform-specific command formatting
- [ ] Keep platform-specific NVM installation in platform states
- [ ] Move Node version management and npm package installation to common
- [ ] Test Node and npm packages install correctly on both platforms

**Complexity:** Medium
**Dependencies:** None
**Estimated Savings:** ~25 lines of duplicate orchestration logic

---

### MED-003: Move WSL Detection Logic to Dedicated State Tree
**Issue:** WSL detection embedded in `linux/config.sls:21-35` and `linux/services.sls`
**Principle Violated:** Linux states should not have WSL-specific conditionals
**Acceptance Criteria:**
- [ ] Create `srv/salt/wsl/init.sls` and `srv/salt/wsl/config.sls`
- [ ] Update `srv/salt/top.sls` with WSL grain matching
- [ ] Remove WSL conditionals from `linux/config.sls` and `linux/services.sls`
- [ ] Test WSL systems get wsl states, regular Linux doesn't
- [ ] Verify SSH listens on port 2222 in WSL, port 22 elsewhere

**Complexity:** Medium
**Dependencies:** Requires understanding of Salt grain matching

---

### MED-004: Create provisioning/common/ Directory Structure
**Issue:** Missing `provisioning/common/` for shared files across platforms
**Acceptance Criteria:**
- [ ] Create `provisioning/common/templates/`, `files/`, `scripts/`
- [ ] Add README.md explaining each subdirectory's purpose
- [ ] Verify Salt file_roots can access `salt://common/` path
- [ ] No immediate file moves (blocks HIGH-003)

**Complexity:** Simple
**Dependencies:** None (enables HIGH-003, MED-001)

---

## Priority 4: LOW (Nice-to-Have)

### LOW-001: Implement Host-Specific Package Filtering
**Issue:** `packages.sls` lacks mechanism to filter packages by host type (deck vs desktop)
**User Decision Required:** Define host type taxonomy
**Acceptance Criteria:**
- [ ] Add host markers to `provisioning/packages.sls`
- [ ] Create Jinja filter for filtering by marker
- [ ] Add `host:type` to pillar data
- [ ] Test packages install correctly based on host type
- [ ] Document marker syntax

**Complexity:** Medium

---

### LOW-002: Add Pre-Commit Hooks
**Issue:** No automated linting/validation before commits
**Acceptance Criteria:**
- [ ] Create `.pre-commit-config.yaml` with hooks (yamllint, shellcheck, PSScriptAnalyzer)
- [ ] Add installation instructions to CONTRIBUTING.md
- [ ] Test hooks prevent commits with linting errors
- [ ] Make optional (not enforced in CI yet)

**Complexity:** Simple

---

### LOW-003: Document Architecture Decisions
**Issue:** Missing ADR (Architecture Decision Records) for key choices
**Acceptance Criteria:**
- [ ] Create `docs/architecture/` directory
- [ ] Write ADR-001: Package manager selection
- [ ] Write ADR-002: File tree separation
- [ ] Write ADR-003: Security defaults
- [ ] Link from main README.md

**Complexity:** Simple

---

### LOW-004: Reorganize Documentation into docs/ Structure
**Issue:** Multiple markdown files in project root should be organized into docs/ subdirectories
**Status:** ✅ COMPLETED (2025-12-28)

**Completed structure:**
```
docs/
├── README.md                           # Main documentation index
├── user-guides/
│   ├── README.md
│   ├── QUICKSTART.md                  # From root README
│   ├── windows-pxe-deployment.md      # From scripts/pxe/windows/README.md
│   └── linux-pxe-deployment.md        # From scripts/pxe/linux/README.md
├── development/
│   ├── README.md
│   ├── CONTRIBUTING.md                # From root
│   ├── CLAUDE.md                      # From root
│   ├── MEMORY-USAGE.md                # From docs/
│   └── testing/
│       ├── README.md
│       ├── QUICKSTART.md              # From tests/
│       ├── IMPLEMENTATION.md          # From tests/
│       └── WINDOWS-TESTING-LOCAL.md   # From docs/
├── security/
│   ├── README.md
│   └── SECURITY.md                    # From root
└── deployment/
    ├── README.md
    └── DEPLOYMENT_SUMMARY.md          # From root

ROOT (simplified):
├── README.md                          # Landing page + docs links
├── TODO.md                            # Kept for high visibility
└── (other project files)
```

**Completion details:**
- Created all subdirectory structure
- Moved all documentation files to appropriate locations
- Created index READMEs for each section
- Updated all internal cross-references
- Updated code file references (enable-openssh.ps1)
- Root README.md simplified with links to docs/

**Acceptance Criteria Met:**
- [x] Create docs/ subdirectory structure
- [x] Move root *.md files to appropriate docs/ subdirs
- [x] Update all internal links between docs
- [x] Update references in code/configs
- [x] Add docs/README.md as index of all documentation
- [x] Keep root README.md as project landing page (simplified, links to docs/)
- [x] Test all links still work

**Complexity:** Simple (completed)
**Dependencies:** None
**Time invested:** 1 hour

---

## Quick Wins (Can Do Immediately)

These tasks have no dependencies and provide immediate value:

1. **CRIT-001**: Fix auto_accept default (5 minutes)
2. **CRIT-002**: Reduce chown scope (5 minutes)
3. **CRIT-003**: Standardize base images (2 minutes)
4. **HIGH-005**: Consolidate healthcheck (5 minutes)
5. **MED-004**: Create provisioning/common/ structure (5 minutes)

**Total Quick Win Time:** ~25 minutes
**Impact:** Security hardening + foundation for refactoring

---

## Parallel Work Streams

### Stream A: Docker Infrastructure
- CRIT-003 → HIGH-001 → HIGH-005
- **Timeline:** 2-3 days

### Stream B: Security & Quick Fixes
- CRIT-001 + CRIT-002 → MED-004
- **Timeline:** 30 minutes

### Stream C: State Refactoring
- MED-004 → HIGH-003 (SSH templates)
- MED-002 (NVM refactor)
- HIGH-004 (git env module)
- **Timeline:** 3-4 days

### Stream D: Architecture Cleanup
- MED-003 (WSL states)
- MED-001 (dotfiles macros)
- **Timeline:** 2-3 days

---

## Summary & Recommendations

### Recommended Execution Order

**Week 1: Security & Foundation**
- Day 1: All quick wins (CRIT-001, CRIT-002, CRIT-003, HIGH-005, MED-004)
- Day 2-3: HIGH-002 (YAML anchors) + HIGH-001 (Dockerfile consolidation)

**Week 2: State Refactoring**
- Day 4-5: HIGH-003 (SSH templates) + HIGH-004 (git env module)
- Day 6-7: MED-002 (NVM refactor) + MED-001 (dotfiles macros)

**Week 3: Architecture Improvements**
- Day 8-10: MED-003 (WSL state tree)
- Day 11+: LOW priority items as needed

This plan reduces technical debt while maintaining production stability.
