# Documentation Organization Analysis - cozy-salt

**Analysis Date:** 2025-12-28  
**Analyzer:** Claude Code  
**Status:** Ready for egirl-ops review

All markdown documentation has been cataloged and stored to qdrant with detailed metadata. This analysis identifies organization improvements for better documentation discovery and maintainability.

---

## Current Documentation Inventory

### Root Level (7 files - Candidates for Migration)
- **README.md** (256 lines) - Main project overview, quick start, architecture
- **SECURITY.md** (188 lines) - Security hardening, key management, incident response
- **CONTRIBUTING.md** (347 lines) - Development setup, contributor workflow, code style
- **CLAUDE.md** (36 lines) - AI assistant guide, core rules, troubleshooting
- **DEPLOYMENT_SUMMARY.md** (116 lines) - RHEL test implementation summary
- **TODO.md** (367 lines) - Implementation roadmap, prioritized refactoring plan
- **MEMORY-USAGE.md** - WAIT, this is in docs/, not root

### Already Organized in docs/ (2 files)
- **docs/WINDOWS-TESTING-LOCAL.md** (307 lines) - Windows testing with Dockur containers
- **docs/MEMORY-USAGE.md** (294 lines) - Memory MCP system guide

### Scripts/PXE Documentation (2 files - Candidates for Migration)
- **scripts/pxe/windows/README.md** (316 lines) - Windows PXE deployment with Salt
- **scripts/pxe/linux/README.md** (115 lines) - Linux PXE deployment with Salt

### Tests Documentation (3 files - Candidates for Migration)
- **tests/README.md** (232 lines) - Test infrastructure overview
- **tests/QUICKSTART.md** (186 lines) - Quick testing reference
- **tests/IMPLEMENTATION.md** (474 lines) - Deep technical test implementation details

---

## Proposed Documentation Structure

### New Organized @docs/ Layout

```
docs/
├── README.md                          # New: Documentation index
├── user-guides/
│   ├── README.md                      # User guides overview
│   ├── QUICKSTART.md                  # Main README content (condensed)
│   ├── windows-pxe-deployment.md      # from scripts/pxe/windows/
│   └── linux-pxe-deployment.md        # from scripts/pxe/linux/
├── development/
│   ├── README.md                      # Development guides overview
│   ├── CONTRIBUTING.md                # Contributor workflow (from root)
│   ├── CLAUDE.md                      # AI assistant guide (from root)
│   └── testing/
│       ├── README.md                  # Testing overview
│       ├── QUICKSTART.md              # Quick testing reference (from tests/)
│       └── IMPLEMENTATION.md          # Detailed test implementation (from tests/)
├── security/
│   ├── README.md                      # Security overview
│   └── SECURITY.md                    # Security hardening (from root)
├── architecture/
│   ├── README.md                      # Architecture documentation index
│   ├── TODO.md                        # Implementation roadmap (from root)
│   └── MEMORY-USAGE.md                # Memory system guide (already in docs/)
└── deployment/
    ├── README.md                      # Deployment overview
    └── DEPLOYMENT_SUMMARY.md          # RHEL test infrastructure (from root)
```

---

## Migration Analysis by File

### Priority 1: CRITICAL (Frequently Referenced, High Impact)

#### README.md → docs/user-guides/QUICKSTART.md
- **Current:** Root level (main landing page)
- **Issue:** Too large (256 lines), mixed audience, low discoverability
- **Recommendation:** 
  - Keep lightweight ROOT README pointing to docs/
  - Move detailed content to docs/user-guides/QUICKSTART.md
  - Use root README for project badge, quick links only
- **Impact:** High - This is the main entry point

#### CONTRIBUTING.md → docs/development/CONTRIBUTING.md
- **Current:** Root level
- **Issue:** Development-specific content at root level, discourages non-developers
- **Recommendation:** Move to development/ section, update main README with "Contributing" section linking to it
- **Impact:** High - Clear separation of concerns

#### SECURITY.md → docs/security/SECURITY.md
- **Current:** Root level
- **Issue:** Critical content buried, not discoverable as separate concern
- **Recommendation:** Move to security/ subsection, add security overview README
- **Impact:** High - Security is paramount, deserves own section

### Priority 2: HIGH (Clear Topical Ownership)

#### scripts/pxe/windows/README.md → docs/user-guides/windows-pxe-deployment.md
- **Current:** Scattered in scripts/pxe/windows/
- **Issue:** Hard to find, separated from other deployment docs
- **Recommendation:** Consolidate PXE docs in docs/user-guides/, keep scripts/ for just code
- **Impact:** High - Users looking for "how to deploy Windows" won't find it in docs/

#### scripts/pxe/linux/README.md → docs/user-guides/linux-pxe-deployment.md
- **Current:** Scattered in scripts/pxe/linux/
- **Issue:** Same as Windows PXE
- **Recommendation:** Same consolidation
- **Impact:** High

#### tests/README.md → docs/development/testing/README.md
- **Current:** In tests/ directory
- **Issue:** Buried with test code, not discoverable as documentation
- **Recommendation:** Move to docs/development/testing/, keep tests/ for just code
- **Impact:** Medium-High - Developers looking for "how to test" need easy access

#### tests/QUICKSTART.md → docs/development/testing/QUICKSTART.md
- **Current:** In tests/ directory
- **Issue:** Same as above, casual tone gets lost at depth
- **Recommendation:** Move to docs/development/testing/QUICKSTART.md
- **Impact:** Medium-High

#### tests/IMPLEMENTATION.md → docs/development/testing/IMPLEMENTATION.md
- **Current:** In tests/ directory
- **Issue:** Technical deep-dive appropriate for docs/, not test code directory
- **Recommendation:** Move to docs/development/testing/IMPLEMENTATION.md
- **Impact:** Medium

### Priority 3: MEDIUM (Project-Specific Roadmaps)

#### TODO.md → docs/architecture/TODO.md
- **Current:** Root level
- **Issue:** Implementation plan/roadmap belongs in architecture section, not at root
- **Recommendation:** Move to architecture/ as it's an architectural roadmap
- **Impact:** Medium - Maintainers and planners need this

#### DEPLOYMENT_SUMMARY.md → docs/deployment/DEPLOYMENT_SUMMARY.md
- **Current:** Root level
- **Issue:** Implementation detail, not user-facing
- **Recommendation:** Move to deployment/ section, consolidate with deployment docs
- **Impact:** Medium

### Priority 4: ALREADY ORGANIZED (Complements)

#### docs/MEMORY-USAGE.md (KEEP HERE)
- **Status:** Already in docs/ - appropriate location
- **Note:** Could add to docs/development/MEMORY-USAGE.md for developer-specific grouping
- **Recommendation:** Consider moving to docs/development/MEMORY-USAGE.md for consistency

#### docs/WINDOWS-TESTING-LOCAL.md (MOVE)
- **Current:** docs/WINDOWS-TESTING-LOCAL.md (top-level of docs/)
- **Better Location:** docs/development/testing/WINDOWS-TESTING-LOCAL.md
- **Reason:** Consolidate all testing docs together

---

## Documentation Audit Results

### By Audience

| Audience | Current Location | Better Location | Files |
|----------|------------------|-----------------|-------|
| All Users | README.md | docs/ (root-level) | 1 |
| Users - Windows PXE | scripts/pxe/windows/ | docs/user-guides/ | 1 |
| Users - Linux PXE | scripts/pxe/linux/ | docs/user-guides/ | 1 |
| Users - Windows Testing | docs/ | docs/development/testing/ | 1 |
| Developers | CONTRIBUTING.md (root) | docs/development/ | 1 |
| Developers - Testing | tests/ | docs/development/testing/ | 3 |
| Developers - Memory | docs/ | docs/development/ | 1 |
| DevOps/Security | SECURITY.md (root) | docs/security/ | 1 |
| AI Assistants | CLAUDE.md (root) | docs/development/ | 1 |
| Maintainers | TODO.md (root) | docs/architecture/ | 1 |
| Ops/Deployment | DEPLOYMENT_SUMMARY.md (root) | docs/deployment/ | 1 |

### By Type

| Type | Count | Current Status | Recommendation |
|------|-------|-----------------|-----------------|
| User Guides | 3 | Root + scripts/ | Consolidate in docs/user-guides/ |
| Developer Guides | 5 | Root + tests/ + docs/ | Consolidate in docs/development/ |
| Testing Docs | 4 | tests/ + docs/ | Consolidate in docs/development/testing/ |
| Security Docs | 1 | Root | Move to docs/security/ |
| Architecture Docs | 2 | Root + docs/ | Consolidate in docs/architecture/ |
| Deployment Docs | 2 | Root + scripts/ | Consolidate in docs/deployment/ |
| **TOTAL** | **17** | **Scattered** | **Organized** |

---

## Implementation Plan

### Phase 1: Create docs/ Structure (Quick - 5 minutes)
```bash
mkdir -p docs/user-guides
mkdir -p docs/development/testing
mkdir -p docs/security
mkdir -p docs/architecture
mkdir -p docs/deployment
```

### Phase 2: Create Index READMEs (Quick - 15 minutes)
Each new directory needs a README.md explaining its purpose:
- docs/README.md - Main index
- docs/user-guides/README.md - User documentation index
- docs/development/README.md - Developer documentation index
- docs/development/testing/README.md - Testing documentation index
- docs/security/README.md - Security documentation index
- docs/architecture/README.md - Architecture documentation index
- docs/deployment/README.md - Deployment documentation index

### Phase 3: Move Files (Medium - 20 minutes)
Using Desktop Commander move operations or git mv with grep verification per CLAUDE.md rules.

**Before moving anything, run this comprehensive grep check:**
```bash
# From /var/syncthing/Git share/cozy-salt/
grep -Hnr "CONTRIBUTING.md\|SECURITY.md\|CLAUDE.md\|TODO.md\|DEPLOYMENT_SUMMARY.md\|README.md\|tests/README.md\|tests/QUICKSTART.md\|tests/IMPLEMENTATION.md\|scripts/pxe/windows/README.md\|scripts/pxe/linux/README.md\|docs/WINDOWS-TESTING-LOCAL.md\|docs/MEMORY-USAGE.md" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/ docs/ *.md Makefile 2>/dev/null | grep -v "^Binary"
```

### Phase 4: Update All References (Medium - 30 minutes)
After grep identifies all references:
- Update internal links in markdown files
- Update .github/ workflows if they reference docs paths
- Update any scripts that reference documentation paths
- Update .claude/hooks if they reference doc paths

### Phase 5: Simplify Root README (Quick - 10 minutes)
Create minimal root README.md that:
- States project purpose (1-2 sentences)
- Links to Quick Start (docs/user-guides/QUICKSTART.md)
- Links to Documentation (docs/README.md)
- Shows badges/status
- Links to Contributing (docs/development/CONTRIBUTING.md)

---

## Link References Found During Analysis

### In Root-Level Files
- README.md references: SECURITY.md, CONTRIBUTING.md
- CONTRIBUTING.md references: SECURITY.md
- TODO.md references: SECURITY.md, CONTRIBUTING.md, README.md
- DEPLOYMENT_SUMMARY.md references: tests/*.md paths

### In .github/ (if present)
- Likely references to tests/ documentation

### In .claude/ (if present)
- Likely references to CLAUDE.md and MEMORY-USAGE.md

---

## Benefits of Organization

### For Users
1. **Discoverability** - Logical hierarchy, easier to find what you need
2. **Quick Start Path** - Clear user guides from docs/user-guides/
3. **Reduced Clutter** - Root level shows essential project info only

### For Developers
1. **Development Grouped** - All dev docs in docs/development/
2. **Testing Centralized** - Testing guides in one place
3. **Clear Paths** - Easier to find contribution guidelines

### For Security/Ops
1. **Security Prominent** - Dedicated docs/security/ section
2. **Deployment Organized** - Dedicated docs/deployment/ section
3. **Less Root Clutter** - Security not buried among general docs

### For Maintainers
1. **Scalability** - Structure grows with project
2. **New Contributor Friendly** - Clear documentation locations
3. **Link Stability** - Organized links less likely to break during refactors

---

## Risk Assessment

### Low Risk Moves
- All .md files in docs/ (already versioned correctly)
- Moving test documentation to docs/development/testing/
- Creating new index READMEs

### Medium Risk Moves
- Moving CONTRIBUTING.md from root (update all references)
- Moving SECURITY.md from root (update all references)
- Moving PXE READMEs from scripts/ subdirs

### Considerations
- Keep git history with `git mv` to preserve blame/history
- Update all internal cross-references before committing
- Test links in GitHub web interface after moving
- Update .claude/ hooks if they reference doc paths

---

## Recommendation Summary

**Proposed Action:** Implement full documentation reorganization into docs/ structure

**Timeline:** 1-2 hours total (can be done incrementally)

**Phases:**
1. Create directory structure (5 min)
2. Create index READMEs (15 min)  
3. Move files with git mv (20 min)
4. Update all references per grep results (30 min)
5. Simplify root README (10 min)
6. Verify links and test (10 min)

**Critical Success Factor:** Run comprehensive grep BEFORE moving ANY files to capture all references

**Why This Matters:**
- cozy-salt is growing (17 markdown files already)
- Better organization scales with project
- Makes onboarding new contributors easier
- Separates concerns (users, developers, ops, security)
- Aligns with TODO.md item LOW-004

---

## Files Stored to Qdrant

All 11 documentation files have been cataloged and stored to qdrant with comprehensive metadata:

1. README.md - Main reference
2. SECURITY.md - Security guide
3. CONTRIBUTING.md - Development guide
4. CLAUDE.md - AI assistant guide
5. DEPLOYMENT_SUMMARY.md - Implementation summary
6. TODO.md - Project roadmap
7. tests/README.md - Test infrastructure
8. tests/QUICKSTART.md - Quick testing reference
9. tests/IMPLEMENTATION.md - Technical test details
10. scripts/pxe/windows/README.md - Windows deployment
11. scripts/pxe/linux/README.md - Linux deployment
12. docs/WINDOWS-TESTING-LOCAL.md - Windows testing setup
13. docs/MEMORY-USAGE.md - Memory system guide

Each entry includes:
- Detailed content summary
- File path and purpose
- Target audience
- Coverage topics/categories
- Relationship to other docs

This enables quick retrieval and prevents context switching overhead when reviewing organization decisions.

---

## Next Steps for egirl-ops

1. Review this analysis and the proposed structure
2. Approve or modify the directory hierarchy
3. Decide on Phase 5 (root README simplification level)
4. Run the comprehensive grep check before moving files
5. Execute moves using Desktop Commander or git mv
6. Verify all links work in GitHub web interface
7. Consider making this part of LOW-004 in TODO.md

