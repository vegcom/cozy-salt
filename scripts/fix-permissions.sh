#!/usr/bin/env bash
# fix-permissions.sh: Automatic permission management for cozy-salt
# Ensures Salt can read all configuration files and scripts are executable.
# Safe to run repeatedly - only changes permissions when needed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT" || exit 1

changed=0

# .sls and .yml/.yaml files → 664
echo "Fixing .sls/.yml/.yaml files (664)..."
find . -type f \( -name "*.sls" -o -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null | \
  while IFS= read -r -d '' file; do
    [[ $(stat -c '%a' "$file") != 664 ]] && chmod 664 "$file" && ((changed++))
  done

# .sh and .py files → 775
echo "Fixing .sh/.py files (775)..."
find . -type f \( -name "*.sh" -o -name "*.py" \) -print0 2>/dev/null | \
  while IFS= read -r -d '' file; do
    [[ $(stat -c '%a' "$file") != 775 ]] && chmod 775 "$file" && ((changed++))
  done

# provisioning/* non-scripts → 664
echo "Fixing provisioning files (664)..."
find ./provisioning -type f ! -name "*.sh" ! -name "*.ps1" -print0 2>/dev/null | \
  while IFS= read -r -d '' file; do
    [[ $(stat -c '%a' "$file") != 664 ]] && chmod 664 "$file" && ((changed++))
  done

# provisioning/*/* executable scripts → 775
echo "Fixing provisioning scripts (775)..."
find ./provisioning \( -path "*/opt-cozy/*.sh" -o -path "*/opt-cozy/*.ps1" \) -type f -print0 2>/dev/null | \
  while IFS= read -r -d '' file; do
    [[ $(stat -c '%a' "$file") != 775 ]] && chmod 775 "$file" && ((changed++))
  done

# Ensure critical directories are searchable
echo "Paths (775)..."
find srv/salt srv/pillar provisioning scripts tests -type d -exec chmod 775 {} \; 2>/dev/null || true

echo "Done: $changed file(s) changed"
exit 0
