# Tests

Linting tests for shell and PowerShell scripts.

## Running Tests

### Shell Scripts (shellcheck)

```bash
# Install shellcheck
apt install shellcheck       # Debian/Ubuntu
brew install shellcheck      # macOS
dnf install shellcheck       # RHEL/Rocky

# Run tests
./tests/test-shellscripts.sh
```

### PowerShell Scripts (PSScriptAnalyzer)

```powershell
# Install PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force

# Run tests
.\tests\test-psscripts.ps1
```

## CI Integration

Add to your CI pipeline:

```yaml
# GitHub Actions example
- name: Lint shell scripts
  run: ./tests/test-shellscripts.sh

- name: Lint PowerShell scripts
  run: pwsh -File ./tests/test-psscripts.ps1
```
