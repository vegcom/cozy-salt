#!/usr/bin/env python3
"""Validate package metadata consistency in provisioning/packages.sls."""

import re
import sys
from pathlib import Path
from typing import Dict, List, Any

import yaml

# Optional: pytest for integration testing
try:
  import pytest

  HAS_PYTEST = True
except ImportError:
  HAS_PYTEST = False


class PackageValidator:
  """Validates package metadata consistency."""

  def __init__(self, packages_file: str = "provisioning/packages.sls"):
    """Initialize validator with packages file."""
    self.packages_file = Path(packages_file)
    self.packages = self._load_packages()
    self.errors: List[str] = []
    self.warnings: List[str] = []

  def _load_packages(self) -> Dict[str, Any]:
    """Load and parse packages.sls, stripping Jinja comments."""
    if not self.packages_file.exists():
      raise FileNotFoundError(f"Packages file not found: {self.packages_file}")

    with open(self.packages_file) as f:
      content = f.read()

    # Remove Jinja comments (text after # that aren't YAML comments)
    # Keep YAML list items with inline comments
    lines = []
    for line in content.split("\n"):
      # Skip pure comment lines
      if line.strip().startswith("#"):
        continue
      # Strip inline comments from list items (keep the package name)
      if line.strip().startswith("- "):
        # Extract package name before comment
        match = re.match(r"^(\s*- [^\s#]+)(.*)", line)
        if match:
          lines.append(match.group(1))
        else:
          lines.append(line)
      else:
        lines.append(line)

    yaml_content = "\n".join(lines)
    return yaml.safe_load(yaml_content) or {}

  def validate_all(self) -> bool:
    """Run all validations. Returns True if all pass."""
    self.validate_conflicts()
    self.validate_excludes()
    self.validate_provides()
    self.validate_capability_groups()
    self.validate_required_packages()

    return len(self.errors) == 0

  def validate_conflicts(self) -> None:
    """Validate conflict groups are well-formed."""
    metadata = self.packages.get("package_metadata", {})
    conflicts = metadata.get("conflicts", {})

    for conflict_name, packages_list in conflicts.items():
      # Check it's a list
      if not isinstance(packages_list, list):
        self.errors.append(
          f"Conflict '{conflict_name}' is not a list: {type(packages_list)}"
        )
        continue

      # Check has at least 2 items
      if len(packages_list) < 2:
        self.errors.append(
          f"Conflict '{conflict_name}' has < 2 options ({len(packages_list)} provided)"
        )

      # Check all items are strings
      for i, pkg in enumerate(packages_list):
        if not isinstance(pkg, str):
          self.errors.append(
            f"Conflict '{conflict_name}[{i}]' is not a string: {type(pkg)}"
          )

  def validate_excludes(self) -> None:
    """Validate excluded packages are documented."""
    metadata = self.packages.get("package_metadata", {})
    excludes = metadata.get("exclude", {})
    provides = metadata.get("provides", {})

    for distro, excluded_packages in excludes.items():
      if not isinstance(excluded_packages, list):
        self.errors.append(f"Exclude section for '{distro}' is not a list")
        continue

      for pkg in excluded_packages:
        if not isinstance(pkg, str):
          self.errors.append(f"Excluded package on '{distro}' is not a string: {pkg}")
          continue

        # Check package is documented somewhere
        if pkg not in provides:
          self.warnings.append(
            f"Excluded package '{pkg}' on '{distro}' has no provides mapping. "
            f"Ensure inline comment explains why (e.g., 'Not in repos (needs EPEL)')"
          )

  def validate_provides(self) -> None:
    """Validate provides mappings are complete."""
    metadata = self.packages.get("package_metadata", {})
    provides = metadata.get("provides", {})
    required_distros = {"ubuntu", "debian", "rhel", "arch"}

    for logical_name, mapping in provides.items():
      if not isinstance(mapping, dict):
        self.errors.append(f"Provides '{logical_name}' is not a dict: {type(mapping)}")
        continue

      # Check all 4 distros are present
      provided_distros = set(mapping.keys())
      if provided_distros != required_distros:
        missing = required_distros - provided_distros
        extra = provided_distros - required_distros
        msg = f"Provides '{logical_name}'"
        if missing:
          msg += f" missing distros: {missing}"
        if extra:
          msg += f" extra distros: {extra}"
        self.errors.append(msg)

      # Check values are strings or lists
      for distro, value in mapping.items():
        if not isinstance(value, (str, list)):
          self.errors.append(
            f"Provides '{logical_name}[{distro}]' is neither string nor list: "
            f"{type(value)}"
          )

  def validate_capability_groups(self) -> None:
    """Validate capability groups are consistent across distros."""
    ubuntu = self.packages.get("ubuntu", {})
    debian = self.packages.get("debian", {})
    rhel = self.packages.get("rhel", {})
    arch = self.packages.get("arch", {})

    ubuntu_groups = set(ubuntu.keys())
    debian_groups = set(debian.keys())
    rhel_groups = set(rhel.keys())
    arch_groups = set(arch.keys())

    # Ubuntu, Debian, RHEL must be identical (except arch)
    if ubuntu_groups != debian_groups:
      diff = ubuntu_groups.symmetric_difference(debian_groups)
      self.errors.append(f"Ubuntu and Debian groups differ: {diff}")

    if ubuntu_groups != rhel_groups:
      diff = ubuntu_groups.symmetric_difference(rhel_groups)
      self.errors.append(f"Ubuntu and RHEL groups differ: {diff}")

    # Arch can have extra groups
    shared_groups = ubuntu_groups
    arch_only_groups = arch_groups - shared_groups
    arch_only_required = {"interpreters", "modern_cli_extras", "fonts", "theming"}

    if arch_only_groups != arch_only_required:
      missing = arch_only_required - arch_only_groups
      extra = arch_only_groups - arch_only_required
      msg = "Arch-only groups mismatch:"
      if missing:
        msg += f" missing {missing}"
      if extra:
        msg += f" extra {extra}"
      self.errors.append(msg)

  def validate_required_packages(self) -> None:
    """Validate required packages section."""
    metadata = self.packages.get("package_metadata", {})
    required = metadata.get("required", {})

    if not isinstance(required, dict):
      self.errors.append(f"Required packages section is not a dict: {type(required)}")
      return

    for category, packages_list in required.items():
      if not isinstance(packages_list, list):
        self.errors.append(f"Required.{category} is not a list: {type(packages_list)}")

  def report(self) -> None:
    """Print validation report."""
    if self.errors:
      print("❌ Package metadata validation FAILED\n")
      print("Errors:")
      for i, error in enumerate(self.errors, 1):
        print(f"  {i}. {error}")
      print()

    if self.warnings:
      print("⚠️  Warnings:")
      for i, warning in enumerate(self.warnings, 1):
        print(f"  {i}. {warning}")
      print()

    if not self.errors:
      print("✅ Package metadata validation PASSED")
      if self.warnings:
        print(
          f"   ({len(self.warnings)} warning{'s' if len(self.warnings) != 1 else ''})"
        )


# ============================================================================
# pytest Integration (optional)
# ============================================================================

if HAS_PYTEST:

  @pytest.fixture(scope="session")
  def validator() -> PackageValidator:
    """Create validator fixture for tests."""
    return PackageValidator()

  def test_conflicts_well_formed(validator: PackageValidator) -> None:
    """Test all conflict groups are valid."""
    validator.validate_conflicts()
    assert not validator.errors, "\n".join(validator.errors)

  def test_excludes_documented(validator: PackageValidator) -> None:
    """Test excluded packages are documented."""
    validator.validate_excludes()
    # Warnings are OK for this test
    assert not validator.errors, "\n".join(validator.errors)

  def test_provides_complete(validator: PackageValidator) -> None:
    """Test provides mappings cover all distros."""
    validator.validate_provides()
    assert not validator.errors, "\n".join(validator.errors)

  def test_capability_groups_consistent(validator: PackageValidator) -> None:
    """Test capability groups are consistent."""
    validator.validate_capability_groups()
    assert not validator.errors, "\n".join(validator.errors)

  def test_required_packages_valid(validator: PackageValidator) -> None:
    """Test required packages structure is valid."""
    validator.validate_required_packages()
    assert not validator.errors, "\n".join(validator.errors)

  def test_all_validations(validator: PackageValidator) -> None:
    """Run all validations together."""
    success = validator.validate_all()
    assert success, "\n".join(validator.errors)


# ============================================================================
# Standalone script
# ============================================================================


def main() -> int:
  """Run as standalone script."""
  try:
    validator = PackageValidator()
    success = validator.validate_all()
    validator.report()
    return 0 if success else 1
  except Exception as e:
    print(f"❌ Validation error: {e}", file=sys.stderr)
    return 2


if __name__ == "__main__":
  sys.exit(main())
