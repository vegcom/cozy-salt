#!/bin/bash
set -e

# Configure minion master and ID from environment variables
MINION_ID="${MINION_ID:-ubuntu-test}"
echo "master: ${SALT_MASTER:-salt}" > /etc/salt/minion.d/master.conf
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

echo "=== Waiting for master to be ready (15s) ==="
sleep 15

echo "=== Waiting for master connectivity ==="
timeout=120
start_time=$(date +%s)
while true; do
  elapsed=$(( $(date +%s) - start_time ))
  [ $elapsed -ge $timeout ] && break

  # Check if we can ping the master (without --local flag)
  if salt-call --timeout=10 test.ping 2>&1 | grep -q 'True'; then
    echo "=== Minion connected to master! Syncing modules ==="
    salt-call saltutil.sync_modules 2>/dev/null || true
    echo "=== Running state.highstate ==="
    # --out=json captured to file for test assertions
    salt-call state.highstate --out=json 2>&1 | tee /tmp/highstate.json
    # Print summary - prefer system python3, fall back to salt's bundled python
    _py=$(command -v python3 || echo /opt/saltstack/salt/bin/python3)
    "$_py" -c "
import json
try:
    d = json.load(open('/tmp/highstate.json')).get('local', {})
    s = sum(1 for v in d.values() if v.get('result') is True)
    f = sum(1 for v in d.values() if v.get('result') is False)
    print(f'Succeeded: {s}  Failed: {f}  Total: {len(d)}')
except Exception as e:
    print(f'(summary failed: {e})')
" 2>/dev/null || true
    echo "=== Highstate complete! Keeping container alive ==="
    exec tail -f /var/log/salt/minion
  fi

  # Show status every 10 seconds
  if [ $((elapsed % 10)) -lt 2 ]; then
    echo "Waiting for master connection... (${elapsed}s/${timeout}s)"
  fi

  sleep 2
done

echo "=== ERROR: Timeout waiting for master connection ==="
echo "=== Hint: Run with SALT_AUTO_ACCEPT=true or accept key manually: salt-key -a ${MINION_ID:-ubuntu-test} ==="
exec tail -f /var/log/salt/minion  # Keep alive for debugging
