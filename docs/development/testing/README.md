# Testing Documentation

Complete testing infrastructure for cozy-salt: linting, state validation, and CI/CD integration.

## Quick Start

Want to test right now?

- **[Quick Start Guide](QUICKSTART.md)** - Get up and running in 5 minutes

## Detailed Information

- **[Implementation Details](IMPLEMENTATION.md)** - Technical deep dive into test architecture and implementation
- **[Windows Testing Setup](WINDOWS-TESTING-LOCAL.md)** - Run Windows tests locally using Dockur containers

## Test Types

### State Application Tests
Test Salt states on different Linux distributions:
- Debian/Ubuntu (linux-test minion)
- RHEL/Rocky (rhel-test minion)

### Static Analysis
- Shell scripts via shellcheck
- PowerShell scripts via PSScriptAnalyzer

### JSON Output Parsing
Automated validation of state results using Python or jq.

## Running Tests

```bash
# Quick test all distributions
make test

# Test specific distribution
make test-linux    # Debian/Ubuntu
make test-rhel     # RHEL/Rocky

# Manual testing
docker compose --profile test-linux up -d
docker logs -f salt-minion-linux-test
```

## CI/CD Integration

Tests are integrated with:
- GitHub Actions (via .github/workflows/)
- GitLab CI (via .gitlab-ci.yml)

Copy the example workflow to enable automated testing on every push.

## Next Steps

- See [Quick Start](QUICKSTART.md) for hands-on testing
- See [Implementation](IMPLEMENTATION.md) for technical details
- See [Contributing Guide](../CONTRIBUTING.md) for development workflow
