#!/bin/bash
# docker.sh - Install Docker Engine in WSL and set up socket proxy for Windows access
set -e

echo "=== Docker Installation for WSL ==="

# Check if running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Warning: This script is designed for WSL environments"
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."

    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker "$USER"

    echo "Docker installed successfully"
else
    echo "Docker already installed: $(docker --version)"
fi

# Start Docker daemon (WSL2 doesn't use systemd by default)
if ! pgrep -x "dockerd" > /dev/null; then
    echo "Starting Docker daemon..."
    sudo dockerd &
    sleep 3
fi

# Verify Docker is running
if docker info &> /dev/null; then
    echo "Docker daemon is running"
else
    echo "Error: Docker daemon failed to start"
    exit 1
fi

echo ""
echo "=== Docker Socket Proxy Setup ==="
echo "Run 'docker compose -f /opt/cozy/docker-proxy.yaml up -d' to start the socket proxy"
echo "Windows can then access Docker at tcp://localhost:2375"
