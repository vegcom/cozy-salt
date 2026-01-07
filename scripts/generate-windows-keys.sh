#!/bin/bash
# generate-windows-keys.sh
# Generates windows-test RSA keys for Salt enrollment
# These keys must match what's generated in the Dockerfile keygen stage

set -e

KEYS_DIR="$(dirname "$0")/pki/minion"

echo "=== Generating Windows Test Keys ==="
mkdir -p "$KEYS_DIR"

# Check if keys already exist
if [ -f "$KEYS_DIR/minion.pem" ] && [ -f "$KEYS_DIR/minion.pub" ]; then
    echo "✓ Keys already exist at $KEYS_DIR"
    exit 0
fi

# Generate RSA keys (same as Dockerfile keygen stage)
echo "Generating RSA key pair..."
openssl genrsa -out "$KEYS_DIR/minion.pem" 4096 2>/dev/null
openssl rsa -in "$KEYS_DIR/minion.pem" -pubout -out "$KEYS_DIR/minion.pub" 2>/dev/null

chmod 644 "$KEYS_DIR/minion.pub"
chmod 600 "$KEYS_DIR/minion.pem"

echo "✓ Keys generated at $KEYS_DIR"
echo "  - minion.pem (600)"
echo "  - minion.pub (644)"
