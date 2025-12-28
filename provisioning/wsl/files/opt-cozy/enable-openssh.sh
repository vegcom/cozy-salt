#!/bin/bash
# enable-openssh.sh - Set up OpenSSH server in WSL on port 2222
# Uses port 2222 to avoid conflict with Windows SSH on port 22
set -e

SSH_PORT=2222

echo "=== OpenSSH Server Setup for WSL ==="

# Install OpenSSH server if not present
if ! command -v sshd &> /dev/null; then
    echo "Installing OpenSSH server..."
    sudo apt-get update
    sudo apt-get install -y openssh-server
fi

# Configure SSH on alternate port
echo "Configuring SSH on port $SSH_PORT..."
sudo sed -i "s/^#Port 22$/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo sed -i "s/^Port 22$/Port $SSH_PORT/" /etc/ssh/sshd_config

# Ensure port is set (in case neither pattern matched)
if ! grep -q "^Port $SSH_PORT" /etc/ssh/sshd_config; then
    echo "Port $SSH_PORT" | sudo tee -a /etc/ssh/sshd_config
fi

# Enable password authentication (for initial setup; disable after adding keys)
sudo sed -i 's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no$/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Start SSH service
echo "Starting SSH service..."
sudo service ssh start || sudo service sshd start

# Verify
if sudo service ssh status &> /dev/null || sudo service sshd status &> /dev/null; then
    echo ""
    echo "=== SSH Server Running ==="
    echo "Port: $SSH_PORT"
    echo ""
    echo "Connect from Windows:"
    echo "  ssh $(whoami)@localhost -p $SSH_PORT"
    echo ""
    echo "To make SSH start automatically, add to your .bashrc or .profile:"
    echo "  sudo service ssh start 2>/dev/null"
else
    echo "Error: SSH service failed to start"
    exit 1
fi
