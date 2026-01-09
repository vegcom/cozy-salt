# Test Infrastructure Review - cozy-salt

**Author:** egirl-ops chaos gremlin  
**Date:** 2025-12-30  
**Status:** Analysis Complete

---

## Executive Summary

Current test infrastructure is functional but shell-heavy. Recommended path: **migrate to pytest** with Makefile orchestration, consolidate tool configs in `pyproject.toml`. Salt API/Reactor approaches are overkill for this use case.

**tl;dr:** shell scripts r giving 2019 energy. pytest is the move~

---

## Current State Assessment

### Test Infrastructure Components

| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| `test-states-json.sh` | `/tests/` | Docker container orchestration + state runs | Working |
| `parse-state-results.py` | `/tests/` | JSON result parsing for CI | Working |
| `test-shellscripts.sh` | `/tests/` | ShellCheck linting wrapper | Working |
| `test-psscripts.ps1` | `/tests/` | PSScriptAnalyzer wrapper | Working |
| `.github/workflows/test-states.yml` | `/.github/workflows/` | CI pipeline | Working |
| `Makefile` | `/` | Test orchestration interface | Comprehensive |

### Available Tools (environment.yml)

```yaml
# Testing
- pytest
- pytest-cov

# Linting  
- black
- isort
- pylint
- yamllint
- salt-lint
- shellcheck
- ansible-lint (bonus)

# Templating
- jinja2
- pyyaml
```

### Current Workflow

```
User                Makefile              Shell Scripts           Docker
  |                    |                       |                    |
  |-- make test ------>|                       |                    |
  |                    |-- test-states-json.sh |                    |
  |                    |                       |-- compose up ----->|
  |                    |                       |<-- wait for done --|
  |                    |                       |-- salt-call ------>|
  |                    |                       |-- parse JSON ------|
  |                    |                       |-- compose down --->|
  |<-- results --------|<----------------------|                    |
```

### Strengths

- Docker Compose profiles for distro isolation
- JSON output capture for structured results
- Pre-shared key authentication (no auto_accept)
- Makefile provides clean user interface
- CI workflow with artifact upload

### Weaknesses

- Shell scripts are platform-dependent (bash-isms)
- Limited test isolation (one big state.highstate per run)
- No parametrized testing
- Scattered linter configs (or missing entirely)
- No pytest integration despite being in environment.yml
- Error handling is basic (grep for completion strings)

---

## Viability Analysis

### A) Salt API and/or Reactor Approach

**Salt API Overview:**
- REST/WebSocket interface to Salt master
- Programmatic state execution via HTTP endpoints
- Requires cherrypy/tornado backend + authentication setup

**Reactor Overview:**
- Event-driven automation on Salt event bus
- Triggers actions based on events (minion/*/start, file changes)
- Designed for operational automation, not testing

**Pros:**
- Native Salt integration
- Can query job status programmatically
- Event-driven workflows possible

**Cons:**
- Significant infrastructure overhead (API server, auth tokens)
- Reactor is async/fire-and-forget - poor for assertions
- Adds complexity without clear testing benefit
- Current docker exec approach is simpler and sufficient

**Verdict: NOT RECOMMENDED**

The current Docker-based approach (docker exec salt-call) is more appropriate for this project. Salt API/Reactor is designed for production orchestration, not test automation. Adding them would increase complexity without meaningful benefit.

> honestly bestie, Salt API for testing is like using a forklift to move a chair. it works but... why~

---

### B) Migrate Tests to Python with pytest

**Overview:**
Leverage pytest (already in environment.yml) to replace shell test runners while keeping Docker container orchestration.

**Architecture:**

```
pytest                           Docker Compose
  |                                    |
  |-- conftest.py fixtures ---------->|
  |     - container_manager           |
  |     - salt_master                 |
  |     - salt_minion(distro)         |
  |                                    |
  |-- test_states.py                  |
  |     @pytest.mark.ubuntu           |
  |     @pytest.mark.rhel             |
  |     @pytest.mark.windows          |
  |                                    |
  |-- test_linting.py                 |
  |     - shellcheck                  |
  |     - yamllint                    |
  |     - salt-lint                   |
```

**Pros:**
- OS-agnostic (works on Linux/Windows/macOS CI runners)
- Rich assertion library with detailed failure messages
- Parametrized tests for distro matrix
- pytest markers for selective test execution
- Native JSON parsing (dict assertions)
- Coverage reporting via pytest-cov
- Fixtures for container lifecycle management
- Better CI integration (JUnit XML output)

**Cons:**
- Migration effort (rewrite shell scripts)
- Learning curve if unfamiliar with pytest
- Need async handling for container waits

**Verdict: RECOMMENDED**

This is the correct approach. Environment.yml already includes pytest/pytest-cov. The existing `parse-state-results.py` demonstrates Python capability is already present.

**Key Libraries to Add:**
```yaml
# Add to environment.yml pip section
- pytest-docker  # or testcontainers-python
- pytest-timeout
- pytest-xdist   # parallel test execution (optional)
```

---

### C) Makefile for Test Orchestration

**Current State:**
Makefile serves as the user interface, delegating to shell scripts.

**Proposed State:**
Makefile remains the interface but delegates to pytest instead.

**Current Targets:**
```makefile
test: test-all
test-ubuntu: ./tests/test-states-json.sh ubuntu
test-rhel: ./tests/test-states-json.sh rhel
test-windows: ./tests/test-states-json.sh windows
lint: lint-shell lint-ps
```

**Proposed Targets:**
```makefile
# Primary test targets (pytest-based)
test: pytest
test-ubuntu: pytest-ubuntu
test-rhel: pytest-rhel
test-windows: pytest-windows
test-all: pytest-all

# pytest invocations
pytest:
	pytest tests/ -v --tb=short

pytest-ubuntu:
	pytest tests/ -v -m ubuntu --tb=short

pytest-rhel:
	pytest tests/ -v -m rhel --tb=short

pytest-windows:
	pytest tests/ -v -m windows --tb=short

pytest-all:
	pytest tests/ -v -m "ubuntu or rhel or windows" --tb=short

# Linting (unified)
lint:
	pytest tests/test_linting.py -v

lint-quick:
	black --check .
	isort --check .
	yamllint srv/
```

**Verdict: KEEP + ENHANCE**

Makefile is a good pattern for user interface. Updating targets to invoke pytest is low effort and maintains backward compatibility for users.

---

### D) pyproject.toml Configuration

**Current State:**
No pyproject.toml exists. Tool configs are missing or scattered.

**Proposed Configuration:**

```toml
[project]
name = "cozy-salt"
version = "1.0.0"
description = "SaltStack IaC for Windows/Linux provisioning"
readme = "README.md"
requires-python = ">=3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
markers = [
    "ubuntu: Ubuntu/Debian state tests",
    "rhel: RHEL/Rocky state tests", 
    "windows: Windows state tests",
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: integration tests requiring Docker",
]
addopts = [
    "-v",
    "--tb=short",
    "--strict-markers",
]
filterwarnings = [
    "ignore::DeprecationWarning",
]

[tool.coverage.run]
source = ["tests"]
omit = [
    "tests/archive-*/*",
    "tests/output/*",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
]

[tool.black]
line-length = 100
target-version = ["py311"]
include = '\.pyi?$'
exclude = '''
/(
    \.git
    | \.venv
    | tests/archive-.*
    | tests/output
)/
'''

[tool.isort]
profile = "black"
line_length = 100
known_first_party = ["tests"]
skip_glob = ["tests/archive-*/*", "tests/output/*"]

[tool.pylint.main]
max-line-length = 100
disable = [
    "C0114",  # missing-module-docstring
    "C0115",  # missing-class-docstring
    "C0116",  # missing-function-docstring (for test functions)
]
ignore-paths = [
    "tests/archive-.*",
    "tests/output",
]

[tool.pylint.design]
max-args = 7
max-locals = 15

# Note: yamllint and salt-lint use their own config files
# .yamllint.yml and .salt-lint (respectively)
```

**Verdict: IMPLEMENT**

This consolidates Python tooling configuration. Yamllint and salt-lint require separate config files (they don't support pyproject.toml yet).

---

## Recommended Migration Path

### Phase 1: Foundation (Effort: 2-4 hours)

1. Create `pyproject.toml` with tool configurations
2. Create `.yamllint.yml` for YAML linting rules
3. Create `.salt-lint` for Salt-specific linting
4. Update `environment.yml` with additional pytest plugins

### Phase 2: Test Migration (Effort: 4-8 hours)

1. Create `tests/conftest.py` with Docker fixtures
2. Convert `test-states-json.sh` logic to `tests/test_states.py`
3. Convert `parse-state-results.py` to pytest assertions
4. Create `tests/test_linting.py` for unified linting tests

### Phase 3: Integration (Effort: 2-4 hours)

1. Update Makefile targets to use pytest
2. Update `.github/workflows/test-states.yml` for pytest
3. Archive or remove shell test scripts
4. Update documentation

### Phase 4: Enhancement (Optional, Effort: 4-8 hours)

1. Add pytest-xdist for parallel test execution
2. Add pytest-html for rich HTML reports
3. Implement pytest-salt-factories for unit testing Salt modules
4. Add pre-commit hooks for linting

---

## Proposed Directory Structure

```
cozy-salt/
├── pyproject.toml              # NEW: Consolidated tool config
├── .yamllint.yml               # NEW: YAML linting rules
├── .salt-lint                  # NEW: Salt-specific linting
├── Makefile                    # UPDATED: pytest targets
├── environment.yml             # UPDATED: additional deps
│
├── tests/
│   ├── __init__.py             # NEW: Make tests a package
│   ├── conftest.py             # NEW: pytest fixtures
│   ├── test_states.py          # NEW: State integration tests
│   ├── test_linting.py         # NEW: Unified linting tests
│   ├── test_syntax.py          # NEW: SLS/Jinja syntax validation
│   │
│   ├── fixtures/               # NEW: Test fixtures
│   │   ├── __init__.py
│   │   └── docker.py           # Container management
│   │
│   ├── output/                 # KEEP: JSON results (gitignored)
│   │   └── .gitignore
│   │
│   └── archive-2025-12-30/     # KEEP: Historical reference
│       ├── test-states-json.sh
│       ├── test-shellscripts.sh
│       ├── test-psscripts.ps1
│       └── parse-state-results.py
```

---

## Migration Effort Estimate

| Phase | Task | Effort | Priority |
|-------|------|--------|----------|
| 1 | pyproject.toml setup | 1-2 hrs | P0 |
| 1 | Linter config files | 1-2 hrs | P0 |
| 2 | conftest.py fixtures | 2-3 hrs | P0 |
| 2 | test_states.py | 2-4 hrs | P0 |
| 2 | test_linting.py | 1-2 hrs | P1 |
| 3 | Makefile updates | 1 hr | P1 |
| 3 | CI workflow updates | 1-2 hrs | P1 |
| 4 | Advanced features | 4-8 hrs | P2 |

**Total Estimated Effort:** 12-24 hours

---

## pyproject.toml Skeleton

Full skeleton provided in Section D above. Key sections:

- `[tool.pytest.ini_options]` - Test discovery, markers, output
- `[tool.coverage.*]` - Coverage reporting configuration
- `[tool.black]` - Code formatting (line-length: 100)
- `[tool.isort]` - Import sorting (profile: black)
- `[tool.pylint.*]` - Linting rules and exclusions

---

## Additional Config Files Needed

### .yamllint.yml
```yaml
extends: default

rules:
  line-length:
    max: 120
    level: warning
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
  comments:
    min-spaces-from-content: 1
  document-start: disable
  indentation:
    spaces: 2
    indent-sequences: consistent

ignore:
  - tests/output/
  - tests/archive-*/
  - .git/
```

### .salt-lint
```yaml
exclude_paths:
  - tests/
  - .git/

skip_list:
  - 204  # Lines should be no longer than 160 chars
  - 206  # Jinja variables should have spaces

warn_list:
  - 201  # Trailing whitespace
```

---

## References

- [Salt's Test Suite Introduction](https://docs.saltproject.io/en/latest/topics/tutorials/writing_tests.html)
- [PyTest Salt Factories](https://pytest-salt-factories.readthedocs.io/en/stable/topics/usage.html)
- [Salt Integration Tests](https://docs.saltproject.io/en/latest/topics/development/tests/integration.html)
- [Salt Unit Tests](https://docs.saltproject.io/en/latest/topics/development/tests/unit.html)

---

## Conclusion

**Recommendation Summary:**

| Approach | Verdict | Rationale |
|----------|---------|-----------|
| Salt API | Skip | Overkill for testing; adds complexity |
| Salt Reactor | Skip | Designed for automation, not assertions |
| pytest Migration | **Implement** | OS-agnostic, rich assertions, CI-friendly |
| Makefile | Keep + Update | Good user interface pattern |
| pyproject.toml | **Implement** | Consolidates tool configs |

The migration to pytest is the clear winner. It leverages existing tools in environment.yml, provides better test isolation, and integrates cleanly with CI pipelines. The shell scripts served their purpose but pytest is simply more maintainable for a project of this complexity.

---

*anyway thats the assessment. pytest is the move, Salt API is a trap, and ur shell scripts r giving legacy vibes~ migrate when ready bestie*
