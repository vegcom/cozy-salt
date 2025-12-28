# Tests

Testing infrastructure for cozy-salt: linting, state validation, and CI/CD integration.

## Test Types

### 1. Static Analysis (Linting)

#### Shell Scripts (shellcheck)

```bash
# Install shellcheck
apt install shellcheck       # Debian/Ubuntu
brew install shellcheck      # macOS
dnf install shellcheck       # RHEL/Rocky

# Run tests
./tests/test-shellscripts.sh
```

#### PowerShell Scripts (PSScriptAnalyzer)

```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force

# Run tests
.\tests\test-psscripts.ps1
```

### 2. State Application Tests

Test Salt states on different Linux distributions using Docker containers.

#### Prerequisites

```bash
# Required
docker
docker-compose

# Optional (for detailed JSON parsing)
jq              # apt install jq / dnf install jq
python3         # Usually pre-installed
```

#### Running State Tests

```bash
# Test on Debian/Ubuntu (linux-test minion)
./tests/test-states-json.sh linux

# Test on RHEL/Rocky (rhel-test minion)
./tests/test-states-json.sh rhel

# Test on both distributions
./tests/test-states-json.sh all
```

The test script will:
1. Build and start the test container(s)
2. Wait for Salt minion to connect and apply states
3. Capture JSON output to `tests/output/<distro>_<timestamp>.json`
4. Parse results and display summary
5. Exit with code 0 (success) or 1 (failure)

#### Manual Testing

```bash
# Start specific test profile
docker compose --profile test-linux up -d
docker compose --profile test-rhel up -d

# Check logs
docker logs salt-minion-linux-test
docker logs salt-minion-rhel-test

# Get JSON output manually
docker exec salt-minion-linux-test salt-call --local state.apply --out=json
docker exec salt-minion-rhel-test salt-call --local state.apply --out=json

# Stop containers
docker compose --profile test-linux down
docker compose --profile test-rhel down
```

### 3. JSON Output Parsing

Parse Salt state JSON output for automated validation.

#### Using Python Parser

```bash
# Parse from file
python3 tests/parse-state-results.py tests/output/linux_20231215_120000.json

# Parse from stdin
docker exec salt-minion-linux-test salt-call --local state.apply --out=json | \
    python3 tests/parse-state-results.py -
```

Exit codes:
- `0` - All states succeeded
- `1` - One or more states failed
- `2` - Invalid input or parsing error

#### Using jq (Shell)

```bash
# Extract failed states
jq -r '.local | to_entries[] | select(.value.result == false) | .key' output.json

# Count succeeded states
jq '[.local | to_entries[] | select(.value.result == true)] | length' output.json

# Get state comments
jq -r '.local | to_entries[] | "\(.key): \(.value.comment)"' output.json
```

## CI Integration

### GitHub Actions Example

```yaml
name: Test Salt States

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Lint shell scripts
        run: ./tests/test-shellscripts.sh

      - name: Lint PowerShell scripts
        run: pwsh -File ./tests/test-psscripts.ps1

  test-states:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro: [linux, rhel]
    steps:
      - uses: actions/checkout@v4

      - name: Test Salt states on ${{ matrix.distro }}
        run: ./tests/test-states-json.sh ${{ matrix.distro }}

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: state-results-${{ matrix.distro }}
          path: tests/output/*.json
```

### GitLab CI Example

```yaml
stages:
  - lint
  - test

lint:shell:
  stage: lint
  script:
    - ./tests/test-shellscripts.sh

test:linux:
  stage: test
  services:
    - docker:dind
  script:
    - ./tests/test-states-json.sh linux
  artifacts:
    when: always
    paths:
      - tests/output/*.json

test:rhel:
  stage: test
  services:
    - docker:dind
  script:
    - ./tests/test-states-json.sh rhel
  artifacts:
    when: always
    paths:
      - tests/output/*.json
```

## Test Output

Test results are saved to `tests/output/` with timestamped filenames:
- `linux_YYYYMMDD_HHMMSS.json` - Debian/Ubuntu test results
- `rhel_YYYYMMDD_HHMMSS.json` - RHEL/Rocky test results

This directory is gitignored to prevent committing test artifacts.

## Troubleshooting

### Container fails to start
```bash
# Check Docker logs
docker compose logs salt-master
docker compose logs salt-minion-linux-test
docker compose logs salt-minion-rhel-test

# Verify images built successfully
docker images | grep salt
```

### State application timeout
```bash
# Increase timeout in test-states-json.sh (default 120s)
# Or manually check container status
docker exec salt-minion-linux-test salt-call --local test.ping
docker exec salt-minion-linux-test cat /var/log/salt/minion
```

### jq not found
```bash
# Tests will still run, but detailed parsing is skipped
# Install jq for better output:
apt install jq          # Debian/Ubuntu
dnf install jq          # RHEL/Rocky
brew install jq         # macOS
```
