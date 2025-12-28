#!/bin/bash
set -e

# Configure minion master and ID from environment variables
echo "master: ${SALT_MASTER:-salt-master}" > /etc/salt/minion.d/master.conf
echo "id: ${MINION_ID:-linux-test}" > /etc/salt/minion.d/id.conf

echo "=== Starting Salt Minion ==="
salt-minion -d

echo "=== Waiting for key acceptance and connectivity ==="
timeout=60
while [ $timeout -gt 0 ]; do
  if salt-call test.ping --local 2>/dev/null | grep -q 'True'; then
    echo "=== Minion connected! Running state.highstate ==="
    salt-call state.highstate --state-output=mixed
    echo "=== Highstate complete! Keeping container alive ==="
    exec tail -f /var/log/salt/minion
  fi
  sleep 2
  timeout=$((timeout-2))
done

echo "=== ERROR: Timeout waiting for minion connection ==="
exit 1
