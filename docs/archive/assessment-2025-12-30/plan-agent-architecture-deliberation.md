# Agent Architecture Deliberation: Makefile + Test Infrastructure Proposals

**Author:** Planning Agent  
**Date:** 2025-12-30  
**Status:** Deliberation Complete

---

## Executive Summary

Two complementary proposals have been analyzed:
1. **Makefile Naming Review** - Bug fixes, naming consistency, new Salt targets
2. **Test Infrastructure Review** - Migration from shell scripts to pytest

These proposals are **complementary but must be carefully sequenced**. The Makefile cleanup provides immediate wins, while pytest migration is a larger effort that benefits from a clean foundation.

**Key Finding:** Both proposals touch the Makefile's test targets. To avoid churn, split Makefile work into two stages: immediate bug fixes/naming before pytest, test target updates after pytest.

---

## Proposal Summaries

### Document 1: Makefile Naming Review

| Category | Count |
|----------|-------|
| Bug fixes | 2 (typo "documentaiton", trailing "d") |
| Renames | 5 (dash consistency, verb placement) |
| Removals/Aliases | 3 (salt-key-status, test-apt, test-linux) |
| New HIGH priority | 8 (salt-doc, salt-cmd, salt-grains, etc.) |
| New MEDIUM priority | 5 (salt-key-accept-all, salt-run-up/down, etc.) |
| New LOW priority | 7 (network, service, package targets) |

### Document 2: Test Infrastructure Review

| Component | Action |
|-----------|--------|
| pyproject.toml | Create (consolidated tool config) |
| .yamllint.yml | Create |
| .salt-lint | Create |
| tests/conftest.py | Create (Docker fixtures) |
| tests/test_states.py | Create (replaces test-states-json.sh) |
| tests/test_linting.py | Create (unified linting) |
| Makefile | Update test targets to invoke pytest |
| CI workflow | Update for pytest |
| Shell scripts | Archive |

---

## Conflict Analysis

### 1. Makefile Test Targets - DIRECT CONFLICT

**Makefile Review:** Keeps test-apt/test-linux as aliases, focuses on naming consistency  
**Test Infrastructure:** Changes test targets to invoke pytest instead of shell scripts

**Resolution:** Makefile naming changes happen FIRST, then pytest migration updates those same targets.

### 2. Makefile Help Output - MINOR OVERLAP

**Makefile Review:** Reorganizes help into logical sections  
**Test Infrastructure:** Updates test section wording for pytest

**Resolution:** Merge these - test section gets pytest wording within the new organizational structure.

### 3. Shell Script Fate - DEPENDENCY

**Makefile Review:** Assumes shell scripts remain (lint-shell calls test-shellscripts.sh)  
**Test Infrastructure:** Archives shell scripts, moves linting to test_linting.py

**Resolution:** Migrate linting to pytest for consistency. The lint Makefile targets will invoke pytest.

---

## Prioritized Implementation Roadmap

### Phase 0: Foundation (Estimated: 2-3 hours)

| Task | File | Priority |
|------|------|----------|
| Create pyproject.toml | `/pyproject.toml` | P0 |
| Create YAML lint config | `/.yamllint.yml` | P0 |
| Create Salt lint config | `/.salt-lint` | P0 |
| Update environment.yml | `/environment.yml` | P0 |

### Phase 1: Makefile Cleanup (Estimated: 2-3 hours)

| Task | Priority |
|------|----------|
| Fix typo "documentaiton" (line 209) | P0 |
| Fix trailing "d" in salt-jobs-clear (line 254) | P0 |
| Rename salt-clear_cache to salt-cache-clear | P1 |
| Rename salt-test-ping to salt-ping | P1 |
| Add HIGH priority targets (salt-doc, salt-cmd, salt-grains) | P1 |
| Reorganize help output into sections | P1 |

### Phase 2: Test Infrastructure Core (Estimated: 3-4 hours)

| Task | File |
|------|------|
| Create tests package | `/tests/__init__.py` |
| Create pytest fixtures | `/tests/conftest.py` |
| Create Docker utilities | `/tests/fixtures/docker.py` |

### Phase 3: Test Migration (Estimated: 4-6 hours)

| Task | File |
|------|------|
| Convert state tests | `/tests/test_states.py` |
| Create Salt result parser | `/tests/lib/salt_results.py` |
| Create linting tests | `/tests/test_linting.py` |

### Phase 4: Integration (Estimated: 2-3 hours)

| Task | File |
|------|------|
| Update Makefile test targets | `/Makefile` |
| Update CI workflow | `/.github/workflows/test-states.yml` |

---

## Common Utility Specifications

### Python Utilities: `/tests/lib/`

#### docker.py - Container Management
```python
class ContainerManager:
    def start_container(self, profile: str, timeout: int = 600) -> str
    def wait_for_highstate(self, container: str, timeout: int = 600) -> bool
    def get_json_output(self, container: str) -> dict
    def stop_container(self, profile: str) -> None
```

#### salt_results.py - Salt Output Parsing
```python
class SaltResultParser:
    def __init__(self, data: dict)
    @property total, succeeded, failed, failed_states
    def assert_all_succeeded(self) -> None
```

### Shell Utilities - NOT RECOMMENDED

Since we are migrating away from shell scripts, creating `scripts/lib/` is not recommended.

---

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Docker fixture reliability | HIGH | Keep shell scripts as fallback during migration |
| CI workflow breakage | HIGH | Run parallel workflows during transition |
| Makefile backward compatibility | MEDIUM | Keep deprecated aliases for 2 cycles |
| pytest marker misuse | MEDIUM | Use --strict-markers |

---

## Effort Summary

| Phase | Hours |
|-------|-------|
| Phase 0: Foundation | 2-3 |
| Phase 1: Makefile Cleanup | 2-3 |
| Phase 2: Test Core | 3-4 |
| Phase 3: Test Migration | 4-6 |
| Phase 4: Integration | 2-3 |

**Total: 13-19 hours** (core phases)

---

## Recommended Next Steps

1. **Immediate (P0):** Fix Makefile bugs (typo, trailing d)
2. **This week:** Complete Phase 0 (pyproject.toml, linter configs)
3. **This week:** Complete Phase 1 (Makefile naming, new targets)
4. **Next sprint:** Phases 2-4 (pytest migration)
