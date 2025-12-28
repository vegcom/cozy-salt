#!/bin/bash
set -e

# Configure auto_accept based on environment variable
# SALT_AUTO_ACCEPT: true (default for testing), false (production)
AUTO_ACCEPT=${SALT_AUTO_ACCEPT:-true}

# Remove existing auto_accept.conf to avoid duplicates
rm -f /etc/salt/master.d/auto_accept.conf

if [ "$AUTO_ACCEPT" = "true" ]; then
    cat > /etc/salt/master.d/auto_accept.conf <<EOF
# Auto-accept minion keys (for testing/trusted networks only)
auto_accept: True
EOF
    echo "=== Salt Master: auto_accept enabled (testing mode) ==="
else
    cat > /etc/salt/master.d/auto_accept.conf <<EOF
# Auto-accept disabled (production mode)
auto_accept: False
EOF
    echo "=== Salt Master: auto_accept disabled (production mode) ==="
fi

echo "=== Starting Salt Master ==="
exec salt-master -l info
