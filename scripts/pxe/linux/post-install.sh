#!/bin/bash
# Post-installation script for Salt minion enrollment
# Runs after OS installation completes via preseed/kickstart

set -e

SALT_MASTER="${SALT_MASTER:-salt-master}"

echo "=== Salt Minion Auto-Enrollment ==="
echo "Salt Master: $SALT_MASTER"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "ERROR: Cannot detect OS"
    exit 1
fi

# Install Salt Minion from Broadcom repo
echo "Installing Salt Minion for $OS..."

case "$OS" in
    ubuntu|debian)
        apt-get update
        apt-get install -y curl gnupg ca-certificates
        curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | \
            gpg --dearmor -o /usr/share/keyrings/salt.gpg
        echo "deb [signed-by=/usr/share/keyrings/salt.gpg arch=amd64] \
            https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" > \
            /etc/apt/sources.list.d/salt.list
        apt-get update
        apt-get install -y salt-minion
        ;;

    rocky|rhel|almalinux|centos)
        dnf install -y yum-utils
        rpm --import https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
        cat > /etc/yum.repos.d/salt.repo <<EOF
[salt-repo]
name=Salt Repository
baseurl=https://packages.broadcom.com/artifactory/saltproject-rpm/
enabled=1
gpgcheck=1
gpgkey=https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
EOF
        dnf install -y salt-minion
        ;;

    *)
        echo "ERROR: Unsupported OS: $OS"
        exit 1
        ;;
esac

# Configure minion
echo "Configuring Salt Minion..."
mkdir -p /etc/salt/minion.d

cat > /etc/salt/minion.d/master.conf <<EOF
master: $SALT_MASTER
EOF

# Set minion ID to hostname
HOSTNAME=$(hostname -f)
cat > /etc/salt/minion.d/id.conf <<EOF
id: $HOSTNAME
EOF

# Enable and start service
echo "Starting Salt Minion..."
systemctl enable salt-minion
systemctl start salt-minion

echo "=== Salt Minion Enrollment Complete ==="
echo "Minion ID: $HOSTNAME"
echo "Master: $SALT_MASTER"
echo ""
echo "On the Salt Master, accept this minion:"
echo "  salt-key -a $HOSTNAME"
echo ""
echo "Then apply states:"
echo "  salt '$HOSTNAME' state.apply"
