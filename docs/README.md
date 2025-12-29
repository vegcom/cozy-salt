# cozy-salt Documentation

Complete documentation for the cozy-salt SaltStack infrastructure-as-code project.

## Getting Started

New to cozy-salt? Start here:

- **[Quick Start Guide](user-guides/)** - Installation options and basic setup
- **[Windows PXE Deployment](user-guides/windows-pxe-deployment.md)** - Automated Windows installation via PXE
- **[Linux PXE Deployment](user-guides/linux-pxe-deployment.md)** - Automated Linux installation via PXE

## For Developers

Contributing to cozy-salt? Read these:

- **[Contributing Guide](development/CONTRIBUTING.md)** - Development setup and workflow
- **[AI Assistant Guide](development/CLAUDE.md)** - Guidelines for AI-assisted development
- **[Memory System](development/MEMORY-USAGE.md)** - Using the Memory MCP for tracking changes

### Testing

Learn how to test your changes:

- **[Testing Overview](development/testing/)** - All things testing
- **[Quick Start](development/testing/QUICKSTART.md)** - Run tests quickly
- **[Windows Testing Setup](development/testing/WINDOWS-TESTING-LOCAL.md)** - Local Windows testing with Dockur
- **[Test Implementation Details](development/testing/IMPLEMENTATION.md)** - Technical deep dive

## Security

- **[Security Hardening Guide](security/SECURITY.md)** - Production hardening, key management, incident response

## Operations & Deployment

- **[Deployment Summary](deployment/DEPLOYMENT_SUMMARY.md)** - Test infrastructure overview

## Project Status

See [TODO.md](../TODO.md) in the project root for the complete implementation roadmap and priorities.

## Structure

```
docs/
├── README.md (you are here)
├── user-guides/          # User-facing guides
├── development/          # Developer documentation
│   └── testing/         # Testing guides
├── security/            # Security hardening
└── deployment/          # Deployment guides
```

---

For project overview and quick links, see the main [README.md](../README.md) at the project root.
