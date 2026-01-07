#!/bin/bash
set -e

# Configure minion master and ID from environment variables
MINION_ID="${MINION_ID:-ubuntu-test}"
echo "master: ${SALT_MASTER:-salt-master}" > /etc/salt/minion.d/master.conf
echo "id: ${MINION_ID}" > /etc/salt/minion.d/id.conf

# Load pre-shared keys if available for this minion ID
# Keys are baked into image at build time for test minions
preload_dir="/etc/salt/pki/minion-preload"
pki_dir="/etc/salt/pki/minion"

if [ -f "$preload_dir/${MINION_ID}.pem" ] && [ ! -f "$pki_dir/minion.pem" ]; then
    echo "=== Loading pre-shared keys for ${MINION_ID} ==="
    mkdir -p "$pki_dir"
    cp "$preload_dir/${MINION_ID}.pem" "$pki_dir/minion.pem"
    cp "$preload_dir/${MINION_ID}.pub" "$pki_dir/minion.pub"
    chmod 400 "$pki_dir/minion.pem"
    chmod 644 "$pki_dir/minion.pub"
fi

# Remove cached master key to handle master restarts
rm -f /etc/salt/pki/minion/minion_master.pub

echo "=== Starting Salt Minion ==="
salt-minion -d

echo "=== Waiting for master connectivity ==="
timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
  # Check if we can ping the master (without --local flag)
  if salt-call test.ping 2>&1 | grep -q 'True'; then
    echo "=== Minion connected to master! Running state.highstate ==="
    salt-call state.highstate --state-output=mixed || true
    echo "=== Highstate complete! Keeping container alive ==="
    exec tail -f /var/log/salt/minion
  fi

  # Show status every 10 seconds
  if [ $((elapsed % 10)) -eq 0 ]; then
    echo "Waiting for master connection... (${elapsed}s/${timeout}s)"
  fi

  sleep 2
  elapsed=$((elapsed + 2))
done

echo "=== ERROR: Timeout waiting for master connection ==="
echo "=== Hint: Run with SALT_AUTO_ACCEPT=true or accept key manually: salt-key -a ${MINION_ID:-ubuntu-test} ==="
exec tail -f /var/log/salt/minion  # Keep alive for debugging
