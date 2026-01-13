# Documentation

Complete documentation for the cozy-salt project.

## Quick Navigation

### For Users & Operators

- **[WINDOWS-ENROLLMENT.md](WINDOWS-ENROLLMENT.md)** - How to provision Windows systems as Salt minions
  - Manual enrollment on existing systems
  - First-boot automation via Dockur
  - Troubleshooting connection issues

### For Contributors

- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Contribution guidelines (in repo root)
  - Project rules (3 core rules)
  - Architecture patterns and conventions
  - Windows environment macro usage
  - Testing and validation procedures

- **[scripts/README.md](../scripts/README.md)** - Script organization and utilities
  - Docker entrypoints
  - Enrollment scripts (Linux & Windows)
  - Utility scripts (permissions, key generation)
  - Integration with Makefile and Docker

- **[provisioning/windows/README.md](../provisioning/windows/README.md)** - Windows provisioning files
  - PowerShell profile modular system
  - File deployment architecture
  - Autounattend.xml for first-boot setup
  - Scheduled tasks and automation
  - Adding new tools to profile

### Reference & Implementation Details

- **[default-cmd-env-variables.md](default-cmd-env-variables.md)** - Windows cmd.run environment macro (✅ Implemented)
  - Explains the `win_cmd()` Jinja macro for standardizing environment variables
  - Reference for extending the macro pattern
  - Success criteria and implementation details

## Documentation Structure

```
docs/
├── README.md                                    (This file - navigation)
├── WINDOWS-ENROLLMENT.md                        (Windows provisioning guide)
└── default-cmd-env-variables.md                 (Windows cmd.run macro reference)
```

## Root-Level Documentation

The following files document the overall project:

| File | Location | Purpose |
|------|----------|---------|
| CONTRIBUTING.md | Root | Contribution guidelines and architecture patterns |
| README.md | Root | Project overview and getting started |
| Makefile | Root | Build automation and common tasks |

## State & Pillar Documentation

State and pillar documentation is embedded as comments in the files themselves:

- `srv/salt/` - Salt states organized by platform (linux/, windows/, common/)
  - Each `.sls` file has header comments explaining its purpose
  - See `CONTRIBUTING.md` for state organization patterns

- `srv/pillar/` - Pillar data for configuration
  - See `.sls` file comments for structure and options
  - Defaults shown in state files

## Getting Started

**First time here?** Start with:

1. [README.md](../README.md) - Project overview
2. [CONTRIBUTING.md](../CONTRIBUTING.md) - Architecture and 3 core rules
3. Pick your context:
   - **Setting up development:** `make help`
   - **Provisioning Windows:** [WINDOWS-ENROLLMENT.md](WINDOWS-ENROLLMENT.md)
   - **Provisioning Linux:** [scripts/README.md](../scripts/README.md)
   - **Understanding architecture:** [provisioning/windows/README.md](../provisioning/windows/README.md)

## Testing & Debugging

See **Makefile** for available test targets:

```bash
make help        # List all available targets
make test-linux  # Test Linux states
make test-windows # Test Windows states
make validate    # Run all validation
```

For debugging guides, see:
- **CONTRIBUTING.md** - "When it breaks" section

## Reference Files

This section contains implementation reference material (not for end users):

### Status of Reference Files

- ✅ **default-cmd-env-variables.md** - Implemented (2026-01-11)
  - Reference for Windows environment variable macro
  - See `srv/salt/macros/windows.sls` for actual implementation

## Contributing Documentation Changes

When adding documentation:

1. **Location:** Put user-facing docs in `docs/`, internal/implementation-specific docs in relevant subdirectories
2. **Naming:** Use clear, descriptive names (README.md for overview, TOPIC.md for details)
3. **Format:** Use GitHub-flavored markdown with clear sections and code examples
4. **Links:** Use relative paths to link between docs: `[link](../other-file.md)`
5. **Cross-reference:** Update this README when adding new documentation

## Questions?

- **About project architecture:** See CONTRIBUTING.md
- **About running tests:** See Makefile and tests/README.md (once created)
- **About Windows setup:** See WINDOWS-ENROLLMENT.md
- **About scripts:** See scripts/README.md
- **About provisioning files:** See provisioning/windows/README.md
