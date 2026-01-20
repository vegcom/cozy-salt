#!/usr/bin/env bash
# fix-permissions.sh - Automatic permission management for cozy-salt
#
# Ensures Salt can read all configuration files and scripts are executable.
# Safe to run repeatedly - only changes permissions when needed.

set -uo pipefail

# Color output
#RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory to find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT" || exit 1

echo -e "${GREEN}[fix-permissions]${NC} Fixing permissions in $REPO_ROOT"

# Counter for changes
CHANGED=0

# Fix .sls files (Salt state files) - need to be readable
echo -e "${GREEN}[1/4]${NC} Checking .sls files..."
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "644" ]]; then
        chmod 644 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 644)"
        ((CHANGED++))
    fi
done < <(find . -type f -name "*.sls" -print0 2>/dev/null)

# Fix .yml/.yaml files (YAML configs) - need to be readable
echo -e "${GREEN}[2/4]${NC} Checking .yml/.yaml files..."
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "644" ]]; then
        chmod 644 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 644)"
        ((CHANGED++))
    fi
done < <(find . -type f \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null)

# Fix .sh files (shell scripts) - need to be executable
echo -e "${GREEN}[3/5]${NC} Checking .sh files..."
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "755" ]]; then
        chmod 755 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 755)"
        ((CHANGED++))
    fi
done < <(find . -type f -name "*.sh" -print0 2>/dev/null)

# Fix .py files (python scripts) - need to be executable
echo -e "${GREEN}[3/5]${NC} Checking .py files..."
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "755" ]]; then
        chmod 755 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 755)"
        ((CHANGED++))
    fi
done < <(find . -type f -name "*.py" -print0 2>/dev/null)

# Fix provisioning files - need to be readable for Salt deployment
# Executable scripts (.sh, .ps1) stay 755, others become 644
echo -e "${GREEN}[4/5]${NC} Checking provisioning files..."
# Non-executable provisioning files (.xml, .toml, .conf, etc.) → 644
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "644" ]]; then
        chmod 644 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 644)"
        ((CHANGED++))
    fi
done < <(find ./provisioning -type f ! -name "*.sh" ! -name "*.ps1" -print0 2>/dev/null)

# Executable provisioning scripts (.sh, .ps1 in *opt-cozy* or *bootstrap*) → 755
while IFS= read -r -d '' file; do
    current_perms=$(stat -c '%a' "$file")
    if [[ "$current_perms" != "755" ]]; then
        chmod 755 "$file"
        echo -e "  ${YELLOW}→${NC} $file ($current_perms → 755)"
        ((CHANGED++))
    fi
done < <(find ./provisioning \( -path "*/opt-cozy/*.sh" -o -path "*/opt-cozy/*.ps1" \) -type f -print0 2>/dev/null)

# Fix critical directories - ensure they're readable/searchable
echo -e "${GREEN}[5/5]${NC} Checking critical directories..."
for dir in srv/salt srv/pillar provisioning scripts tests; do
    if [[ -d "$dir" ]]; then
        find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
    fi
done

# Summary
echo ""
if [[ $CHANGED -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} All permissions correct (no changes needed)"
else
    echo -e "${GREEN}✓${NC} Fixed $CHANGED file(s)"
fi

exit 0
