# Package Metadata: Validation & Enforcement

This document covers validating and enforcing package metadata consistency across distros and detecting conflicts, exclusions, and name mapping issues.

## Metadata Structure

Package metadata in `provisioning/packages.sls` contains cross-cutting concerns:

```yaml
package_metadata:
  conflicts: # Packages that conflict (user chooses one)
  optional: # Nice-to-have packages
  required: # Core packages always present
  exclude: # Packages unavailable on specific distros
  provides: # Name mappings across distros
```

## Validation Rules

### 1. Conflicts Validation

**Rule**: Each conflict group must be comprehensive and non-overlapping.

**Check**:

```python
# Each conflict set should have alternatives for users
conflicts[key] must have:
  - At least 2 items (single items don't conflict)
  - One per distro or clearly documented why skipped
  - Comments explaining the choice (Debian preferred, RHEL alternative, etc.)

# Example: Valid conflict
database_mysql:
  - mysql              # Ubuntu/Debian
  - mariadb            # Ubuntu/Debian alternative
  - percona-server     # Ubuntu/Debian alternative
```

**Invalid examples**:

- Single-item conflict (not really a conflict)
- Incomplete (missing distro variants without reason)
- Undocumented tradeoffs

### 2. Exclude Validation

**Rule**: Excluded packages must exist in `provides` section or have inline comment.

**Check**:

```python
# For each exclude entry:
for distro, excluded_packages in package_metadata.exclude.items():
  for package in excluded_packages:
    if package not in provides:
      # Must have comment explaining why
      require inline comment like "Not available", "Use X instead", etc.

# Example: Valid exclude
exclude:
  rhel:
    - duf  # Not in base RHEL repos (needs EPEL)

# Example: Invalid exclude
exclude:
  arch:
    - random_package  # [NO COMMENT - should explain why]
```

**Common reasons**:

- "Not in base repos (needs EPEL)" - package exists but requires extra repo
- "Use X instead" - replaced by alternative package
- "Different name on [distro]" - see provides section
- "Not available" - package doesn't exist for this distro

### 3. Provides Validation

**Rule**: Every name mapping must reflect actual package names across distros.

**Check**:

```python
# For each provides entry:
for package_logical_name, mapping in provides.items():
  require len(mapping) == 4  # ubuntu, debian, rhel, arch

  # Each value must be:
  # - String: single package (most common)
  # - List: multiple packages (RHEL gcc+gcc-c++, Arch base-devel)
  # - Comment: explain if unusual (e.g., "GROUP on Arch")

# Example: Valid provides
provides:
  build_essentials:
    ubuntu: build-essential         # Single package
    debian: build-essential         # Single package
    rhel: [gcc, gcc-c++, make, ...] # List (multiple packages)
    arch: base-devel                # Group (comment required)

# Example: Invalid provides
provides:
  something:
    ubuntu: package-a
    debian: package-b
    # [MISSING RHEL AND ARCH]
```

**Enforcement**:

- Every logical package name needs all 4 distros
- Comments required for non-standard mappings (lists, groups, unusual names)

### 4. Capability Group Validation

**Rule**: All 4 distros must define the same capability groups (except Arch-only groups).

**Check**:

```python
# For each distro (ubuntu, debian, rhel, arch):
ubuntu_groups = set(ubuntu.keys())      # {core_utils, build_tools, ...}
debian_groups = set(debian.keys())
rhel_groups = set(rhel.keys())
arch_groups = set(arch.keys())

# Ubuntu, Debian, RHEL must be identical
assert ubuntu_groups == debian_groups == rhel_groups, \
  "Shared groups must be identical"

# Arch can have extra Arch-only groups
arch_only_groups = arch_groups - ubuntu_groups
required_arch_only = {
  'interpreters', 'modern_cli_extras', 'fonts', 'theming'
}
assert arch_only_groups == required_arch_only, \
  "Arch-only groups must be exactly: interpreters, modern_cli_extras, fonts, theming"
```

**Common errors**:

- Typo in group name: `build_tools` vs `build_tool` (inconsistent)
- Group exists in Ubuntu but not RHEL
- Missing Arch-only groups

### 5. Package Name Consistency

**Rule**: Package names within groups should be consistent across distros (unless in provides).

**Check**:

```python
# For each package in a capability group:
for group in common_groups:
  ubuntu_packages = ubuntu[group]
  rhel_packages = rhel[group]

  # If package appears in both, should be:
  # - Same name (if same package)
  # - OR in provides section (if different names)
  # - OR in exclude section (if unavailable)

  for pkg in ubuntu_packages:
    if pkg not in rhel_packages:
      # Check if RHEL has alternative in provides
      assert is_in_provides(pkg), \
        f"Package '{pkg}' in Ubuntu but not RHEL. Add to provides or exclude."
```

**Example**:

```yaml
ubuntu:
  core_utils:
    - vim # In Ubuntu
rhel:
  core_utils:
    - vim-enhanced # Different name in RHEL

# Must be in provides:
provides:
  vim:
    ubuntu: vim
    rhel: vim-enhanced
```

## Enforcement Implementation

### Static Validation Script

Create `tests/validate_packages.py`:

```python
#!/usr/bin/env python3
"""Validate package metadata consistency."""

import yaml
import sys
from pathlib import Path

def validate_packages():
    """Validate provisioning/packages.sls structure."""
    packages_file = Path('provisioning/packages.sls')

    with open(packages_file) as f:
        # Extract YAML from Jinja comments
        content = f.read()
        packages = yaml.safe_load(content)

    errors = []

    # 1. Check conflicts
    for conflict_name, packages_list in packages['package_metadata']['conflicts'].items():
        if len(packages_list) < 2:
            errors.append(f"Conflict '{conflict_name}' has < 2 options")
        for pkg in packages_list:
            if not isinstance(pkg, str):
                errors.append(f"Conflict '{conflict_name}' has non-string entry: {pkg}")

    # 2. Check excludes have comments/provides mapping
    for distro, excluded in packages['package_metadata']['exclude'].items():
        for pkg in excluded:
            in_provides = pkg in packages['package_metadata']['provides']
            # Also check for inline comment (manual check via review)
            if not in_provides:
                errors.append(f"Excluded package '{pkg}' on {distro} not in provides. Add comment.")

    # 3. Check provides completeness
    for logical_name, mapping in packages['package_metadata']['provides'].items():
        required_distros = {'ubuntu', 'debian', 'rhel', 'arch'}
        if set(mapping.keys()) != required_distros:
            missing = required_distros - set(mapping.keys())
            errors.append(f"Provides '{logical_name}' missing distros: {missing}")

    # 4. Check capability groups consistency
    distros = {'ubuntu': packages['ubuntu'], 'debian': packages['debian'],
               'rhel': packages['rhel'], 'arch': packages['arch']}

    shared_groups = set(packages['ubuntu'].keys())
    for distro_name, distro_pkg in distros.items():
        if distro_name == 'arch':
            continue  # Arch can have extra
        if set(distro_pkg.keys()) != shared_groups:
            missing = shared_groups - set(distro_pkg.keys())
            extra = set(distro_pkg.keys()) - shared_groups
            if missing:
                errors.append(f"{distro_name} missing groups: {missing}")
            if extra:
                errors.append(f"{distro_name} has extra groups: {extra}")

    # 5. Check Arch has required Arch-only groups
    arch_only_required = {'interpreters', 'modern_cli_extras', 'fonts', 'theming'}
    arch_groups = set(packages['arch'].keys())
    arch_specific = arch_groups - shared_groups
    if arch_specific != arch_only_required:
        errors.append(f"Arch groups mismatch. Expected: {arch_only_required}, got: {arch_specific}")

    if errors:
        print("Package metadata validation errors:")
        for error in errors:
            print(f"  ✗ {error}")
        return False

    print("✓ Package metadata validation passed")
    return True

if __name__ == '__main__':
    sys.exit(0 if validate_packages() else 1)
```

### Pre-commit Hook Integration

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: validate-packages
      name: Validate package metadata
      entry: python tests/validate_packages.py
      language: system
      files: provisioning/packages.sls
      stages: [commit]
```

### Salt State Enforcement

At deployment, ensure requested packages don't violate conflicts:

```sls
# srv/salt/linux/install.sls
{% set requested_packages = packages[grains['os']].get(capability_group, []) %}

# Before installing, check for conflicts
{% for conflict_group, conflicting_packages in packages.package_metadata.conflicts.items() %}
  {% set found = [] %}
  {% for pkg in requested_packages %}
    {% if pkg in conflicting_packages %}
      {% do found.append(pkg) %}
    {% endif %}
  {% endfor %}
 set requested_packages = packages[grains['os']].get(capability_group, []) %}

# Before installing, check for conflicts
{% for conflict_group, conflicting_packages in packages.package_metadata.conflicts.items() %}
  {% set found = [] %}
  {% for pkg in requested_packages %}
    {% if pkg in conflicting_packages %}
      {% do found.append(pkg) %}
    {% endif %}
  {% endfor %}
  
  {% if found|length > 1 %}
    # Conflict detected - fail with clear message
    fail_conflict_{{ conflict_group }}:
      cmd.run:
        - name: "echo 'Conflict: Cannot install both {{ found|join(' and ') }}. Choose one.'; exit 1"
  {% endif %}
{% endfor %}

install_packages:
  pkg.installed:
    - pkgs: {{ requested_packages }}
```

## Validation Checklist

Before committing changes to `provisioning/packages.sls`:

- [ ] **All 4 distros have same capability groups** (except Arch-only)
  - Arch can have `interpreters`, `modern_cli_extras`, `fonts`, `theming`
  - Ubuntu/Debian/RHEL must be identical otherwise

- [ ] **No packages in two conflict groups**
  - Each package should only appear in one `conflicts` section

- [ ] **All excluded packages have reason**
  - Comments like "Not in repos", "Use X instead", etc.
  - OR present in `provides` with alternative

- [ ] **All `provides` mappings are complete**
  - Every logical package has ubuntu, debian, rhel, arch entries
  - Lists or unusual mappings have comments

- [ ] **No typos in group names** across distros
  - Case-sensitive: `build_tools` not `build_tool`
  - Run validation script to catch

- [ ] **Comments explain distro differences**
  - Why package names differ across distros
  - When optional packages are included/excluded

## Common Validation Failures

### Error: Conflict in conflict group

```
✗ Cannot install both mysql and mariadb. Choose one.
```

**Fix**: Check pillar or state logic - ensure only one is requested per system

### Error: Package group missing on distro

```
✗ rhel missing groups: {'modern_cli_extras'}
```

**Fix**: Add `modern_cli_extras` to RHEL section, or remove from shared groups

### Error: Provides mapping incomplete

```
✗ Provides 'vim' missing distros: {'arch'}
```

**Fix**: Add arch entry to vim provides mapping with correct package name

### Error: Excluded package not documented

```
✗ Excluded package 'duf' on rhel not in provides. Add comment.
```

**Fix**: Add comment to exclude entry: `- duf  # Not in base RHEL repos (needs EPEL)`

## Testing Validation

Run validation script:

```bash
# Test metadata consistency
python tests/validate_packages.py

# Run as pytest test
pytest tests/validate_packages.py::test_metadata_structure -v

# Integration test (install capability on all distros)
make test-ubuntu      # Check Ubuntu packages install
make test-rhel        # Check RHEL packages install
```

## Related Documentation

- `docs/package-management.md` - Overall package architecture
- `provisioning/packages.sls` - Actual package definitions
- `srv/salt/linux/install.sls` - How packages are installed
- `srv/salt/windows/install.sls` - Windows package installation
- `tests/validate_packages.py` - Validation script

## See Also

- **Conflict resolution**: How to choose between conflicting packages
- **Missing packages**: When to use `provides` vs `exclude`
- **Arch-specific handling**: Special groups for Arch-only capabilities
