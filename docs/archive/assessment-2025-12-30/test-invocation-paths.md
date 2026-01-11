# Test Invocation Paths - cozy-salt

## Overview
This document enumerates all paths that invoke tests in the cozy-salt infrastructure.

## Makefile Test Targets

### State Testing
```makefile
test-ubuntu    → ./tests/test-states-json.sh ubuntu
test-rhel      → ./tests/test-states-json.sh rhel  
test-windows   → ./tests/test-states-json.sh windows
test-all       → ./tests/test-states-json.sh all
test-quick     → docker compose exec -t salt-minion-ubuntu-test salt-call state.highstate --out=json
```

### Linting
```makefile
lint-shell     → ./tests/test-shellscripts.sh
lint-ps        → pwsh -File ./tests/test-psscripts.ps1
lint           → lint-shell + lint-ps
```

### Artifacts
```makefile
clean          → rm -f tests/output/*.json
```

## GitHub Actions Workflow
**File**: `.github/workflows/test-states.yml`

### Lint Job
- Runs on: `ubuntu-latest`
- Steps:
  1. Checkout code
  2. Lint shell scripts: `./tests/test-shellscripts.sh`
  3. Setup PowerShell
  4. Lint PowerShell scripts: `pwsh -File ./tests/test-psscripts.ps1`

### Test States Job
- Runs on: `ubuntu-latest`
- Matrix: `[linux, rhel]`
- Steps:
  1. Checkout code
  2. Setup Docker Buildx
  3. Run tests: `./tests/test-states-json.sh ${{ matrix.distro }}`

## Test Files (Archived)
**Location**: `tests/archive-2025-12-30/`

1. **test-states-json.sh** - Main state testing script
   - Invoked with: `ubuntu`, `rhel`, `windows`, or `all`
   - Outputs JSON to `tests/output/*.json`

2. **test-shellscripts.sh** - Shell script linting
   - Uses shellcheck if available

3. **test-psscripts.ps1** - PowerShell script linting
   - Requires pwsh

4. **parse-state-results.py** - JSON result parser
   - Python utility for test output analysis

## Test Output
- **Directory**: `tests/output/`
- **Format**: JSON files from state.highstate
- **Cleanup**: `make clean` removes `*.json` files

## Dependencies
From `environment.yml`:
- shellcheck (shell linting)
- yamllint, salt-lint, ansible-lint (YAML/Salt linting)
- pytest, pytest-cov (Python testing framework)
- pylint, black, isort (Python code quality)

## Notes
- Tests run in Docker containers defined in `docker-compose.yml`
- Windows tests require KVM (via Dockur)
- Test profiles: `test-linux`, `test-rhel`, `test-windows`
