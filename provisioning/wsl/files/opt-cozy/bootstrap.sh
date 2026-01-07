#!/bin/bash
# bootstrap.sh - One-shot WSL setup for cozy-salt
# Run this script to set up everything from scratch
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  cozy-salt WSL Bootstrap"
echo "=========================================="
echo ""

# Step 1: Install Docker
echo "[1/3] Installing Docker..."
bash "$SCRIPT_DIR/docker.sh"
echo ""

# Step 2: Enable SSH (optional but recommended)
read -p "Enable SSH server on port 2222? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/enable-openssh.sh"
fi
echo ""

# Step 3: Start Salt Master
echo "[3/3] Starting Salt Master..."
bash "$SCRIPT_DIR/salt.sh"

echo ""
echo "=========================================="
echo "  Bootstrap Complete!"
echo "=========================================="
echo ""
echo "Salt Master is running in Docker."
echo ""
echo "Windows Setup:"
echo "  1. Create Docker context:"
echo "     docker context create wsl --docker \"host=tcp://localhost:2375\""
echo "     docker context use wsl"
echo ""
echo "  2. Install Salt Minion (run as Administrator):"
echo "     cd \\path\\to\\cozy-salt"
echo "     .\\scripts\\install-win-minion.ps1 -Master <wsl-ip>"
echo ""
echo "  3. Accept the minion key:"
echo "     docker exec salt-master salt-key -A"
echo ""
echo "  4. Apply states:"
echo "     docker exec salt-master salt '*' state.apply"
