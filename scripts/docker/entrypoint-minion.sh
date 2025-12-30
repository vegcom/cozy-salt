#!/bin/bash
set -e

# Start systemd as PID 1 if available (required for full state testing with services)
# This allows states that manage systemd services (nginx, docker, etc.) to work correctly
if [ -x /lib/systemd/systemd ]; then
  echo "=== Starting systemd as init system ==="
  
  # Start systemd in background
  /lib/systemd/systemd --system &
  SYSTEMD_PID=$!
  
  # Wait for systemd to be ready (max 30 seconds)
  for i in {1..30}; do
    if systemctl is-system-running >/dev/null 2>&1; then
      echo "Systemd ready!"
      break
    fi
    if [ $i -eq 30 ]; then
      echo "WARNING: Systemd did not fully initialize in time"
    fi
    sleep 1
  done
fi

# Configure minion master and ID from environment variables
echo "master: ${SALT_MASTER:-salt-master}" > /etc/salt/minion.d/master.conf
echo "id: ${MINION_ID:-ubuntu-test}" > /etc/salt/minion.d/id.conf

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
