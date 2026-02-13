#!/bin/bash
# generate-windows-keys.sh: Generate windows-test RSA keys for Salt enrollment

set -e

KEYS_DIR="$(dirname "$0")/pki/minion"
mkdir -p "$KEYS_DIR"

# Check if keys already exist
if [ -f "$KEYS_DIR/minion.pem" ] && [ -f "$KEYS_DIR/minion.pub" ]; then
    exit 0
fi

# Generate RSA keys (matches Dockerfile keygen stage)
openssl genrsa -out "$KEYS_DIR/minion.pem" 4096 2>/dev/null
openssl rsa -in "$KEYS_DIR/minion.pem" -pubout -out "$KEYS_DIR/minion.pub" 2>/dev/null

chmod 644 "$KEYS_DIR/minion.pub"
chmod 600 "$KEYS_DIR/minion.pem"
