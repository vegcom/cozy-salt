#!/bin/bash
# salt.sh - Clone cozy-salt and run Salt Master in Docker
set -e

REPO_URL="${COZY_SALT_REPO}"
if [[ -z "$REPO_URL" ]]; then
    echo "Error: COZY_SALT_REPO environment variable must be set"
    echo "Example: export COZY_SALT_REPO=https://github.com/your-org/cozy-salt.git"
    exit 1
fi
COZY_DIR="/opt/cozy/cozy-salt"

echo "=== Salt Master Setup ==="

# Ensure Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Run docker.sh first."
    exit 1
fi

# Clone or update cozy-salt repo
if [ -d "$COZY_DIR" ]; then
    echo "Updating cozy-salt..."
    cd "$COZY_DIR"
    git pull --ff-only || echo "Warning: Could not pull updates"
else
    echo "Cloning cozy-salt..."
    sudo mkdir -p /opt/cozy
    sudo chown "$USER:$USER" /opt/cozy
    git clone "$REPO_URL" "$COZY_DIR"
    cd "$COZY_DIR"
fi

# Start the Docker socket proxy first (for Windows access)
echo "Starting Docker socket proxy..."
docker compose -f /opt/cozy/docker-proxy.yaml up -d

# Start Salt Master
echo "Starting Salt Master..."
docker compose up -d

# Wait for Salt Master to be healthy
echo "Waiting for Salt Master to be ready..."
for i in {1..30}; do
    if docker compose exec -T salt-master salt-run manage.status &> /dev/null; then
        echo "Salt Master is ready!"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Show status
echo ""
echo "=== Status ==="
docker compose ps

echo ""
echo "=== Next Steps ==="
echo "1. On Windows, set up Docker context:"
echo "   docker context create wsl --docker \"host=tcp://localhost:2375\""
echo "   docker context use wsl"
echo ""
echo "2. Install Salt Minion on Windows:"
echo "   .\\scripts\\install-win-minion.ps1 -Master \$(hostname -I | awk '{print \$1}')"
echo ""
echo "3. Accept minion keys:"
echo "   docker compose exec salt-master salt-key -A"
echo ""
echo "4. Apply states:"
echo "   docker compose exec salt-master salt '*' state.apply"
