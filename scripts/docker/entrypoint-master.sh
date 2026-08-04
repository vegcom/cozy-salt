#!/bin/bash
set -e

# Generate master keys if they don't exist (CI environment)
# Local dev bind-mounts keys from host, so this only runs in CI
# Note: Docker creates empty directories when bind-mounting non-existent files
master_pki="/etc/salt/pki/master"
if [[ ! -f "${master_pki}/master.pem" ]]; then
    echo "=== Generating master keys ==="
    mkdir -p "${master_pki}"
    # Remove empty directories Docker may have created from missing bind mounts
    [[ -d "${master_pki}/master.pem" ]] && rmdir "${master_pki}/master.pem" 2>/dev/null || true
    [[ -d "${master_pki}/master.pub" ]] && rmdir "${master_pki}/master.pub" 2>/dev/null || true
    openssl genrsa -out "${master_pki}/master.pem" 4096 2>/dev/null
    openssl rsa -in "${master_pki}/master.pem" -pubout -out "${master_pki}/master.pub" 2>/dev/null
    chmod 600 "${master_pki}/master.pem"
    chmod 644 "${master_pki}/master.pub"
    chown -R salt:salt "${master_pki}"
    echo "  + Generated master.pem and master.pub"
fi

# Pre-accept minion keys from build-time generated keys
# Keys are baked into image at /etc/salt/pki/master/minions-preload/
# This ensures test minions are ready immediately without manual acceptance
preload_dir="/etc/salt/pki/master/minions-preload"
minions_dir="/etc/salt/pki/master/minions"

if [[ -d "${preload_dir}" ]]; then
    echo "=== Pre-accepting minion keys ==="
    mkdir -p "${minions_dir}"
    denied_dir="/etc/salt/pki/master/minions_denied"
    for key_file in "${preload_dir}"/*.pub; do
        if [[ -f "${key_file}" ]]; then
            minion_id=$(basename "${key_file}" .pub)
            # Remove from denied (stale denied + valid accepted = auth failure)
            if [[ -f "${denied_dir}/${minion_id}" ]]; then
                rm -f "${denied_dir}/${minion_id}"
                echo "  - Cleared denied key for ${minion_id}"
            fi
            # Always sync accepted key from preload (ensures key matches minion image)
            cp "${key_file}" "${minions_dir}/${minion_id}"
            echo "  + Pre-accepted ${minion_id}"
        fi
    done
fi

# Set cozy-salt-svc password for SaltGUI PAM auth
if [[ -n "${SALT_API_USER_PASS}" ]]; then
    echo "cozy-salt-svc:${SALT_API_USER_PASS}" | chpasswd
    echo "[entrypoint] cozy-salt-svc password set"
else
    echo "[entrypoint] WARNING: SALT_API_USER_PASS not set — SaltGUI login will fail"
fi

# minion config
echo "[entrypoint] Configuring master as local minion..."
mkdir -p /etc/salt/minion.d
echo "master: localhost" > /etc/salt/minion.d/master.conf
echo "id: salt" > /etc/salt/minion.d/id.conf

# Auth
autosign_file="/etc/salt/autosign.d/autosign_file.conf"
autoreject_file="/etc/salt/autosign.d/autoreject_file.conf"
echo "[entrypoint] Writing master aclAuth config..."
if [ ! -d /etc/salt/autosign.d ]; then
    mkdir -p /etc/salt/autosign.d
    touch ${autosign_file}
    touch ${autoreject_file}
fi

# Mongo
echo "[entrypoint] Initialising mongo credentials..."
mongo_dir="/srv/data/mongo"
mkdir -p "${mongo_dir}"
mongo_pass_file="${mongo_dir}/password"
if [[ ! -f "${mongo_pass_file}" ]]; then
    openssl rand -base64 48 | tr -d '/+=' | head -c 32 > "${mongo_pass_file}"
    chmod 664 "${mongo_pass_file}"
    echo "  + mongo password generated"
else
    echo "  + mongo password exists"
fi
echo "${MONGO_HOST:-mongo}" > "${mongo_dir}/host"

echo "[entrypoint] Writing master mongo returner config..."
mongo_pass=$(cat "${mongo_pass_file}")
cat > /etc/salt/master.d/mongo-returner-generated.conf <<EOF
# Generated at container startup — do not edit, do not commit (see .gitignore)
# docs configuration/master: https://docs.saltproject.io/en/latest/ref/configuration/master.html
mongo.host: ${MONGO_HOST:-mongo}
mongo.port: 27017
mongo.db: salt
mongo.user: salt
mongo.password: ${mongo_pass}
mongo.authdb: admin
EOF
echo "  + mongo-returner-generated.conf written"

# Sqlite
echo "[entrypoint] Initialising sqlite3 returner schema..."
mkdir -p /srv/data/sqlite || true
python3 -c "
import sqlite3, os, shutil
target = '/srv/data/sqlite/salt_returns.db'
tmp    = '/tmp/salt_returns_init.db'
conn = sqlite3.connect(tmp)
conn.execute('PRAGMA journal_mode=WAL')
conn.execute('CREATE TABLE IF NOT EXISTS salt_returns (fun TEXT KEY, jid TEXT KEY, id TEXT KEY, fun_args TEXT, date TEXT NOT NULL, full_ret TEXT NOT NULL, success TEXT NOT NULL)')
conn.execute('CREATE TABLE IF NOT EXISTS jids (jid TEXT PRIMARY KEY, load TEXT NOT NULL)')
conn.commit()
conn.close()
if not os.path.exists(target):
    shutil.move(tmp, target)
    os.chmod(target, 0o664)
    print('  + salt_returns.db created (WAL mode)')
else:
    os.unlink(tmp)
    print('  + salt_returns.db already exists, skipping')

"
chown salt:salt /srv/data/sqlite/salt_returns.db 2>/dev/null || true

# Load pre-shared key so master's pre-accepted pub matches what minion presents
preload_dir="/etc/salt/pki/minion-preload"
pki_dir="/etc/salt/pki/minion"
if [ -f "${preload_dir}/salt.pem" ] && [ ! -f "${pki_dir}/minion.pem" ]; then
    echo "  + Loading pre-shared keys for salt minion"
    mkdir -p "${pki_dir}"
    cp "${preload_dir}/salt.pem" "${pki_dir}/minion.pem"
    cp "${preload_dir}/salt.pub" "${pki_dir}/minion.pub"
    chmod 400 "${pki_dir}/minion.pem"
    chmod 644 "${pki_dir}/minion.pub"
    chown -R salt:salt "${pki_dir}"
fi
rm -f "${pki_dir}/minion_master.pub"

salt-minion -d
echo "  + salt-minion started (id: salt -> localhost)"

echo "[entrypoint] Starting wsdd..."
wsdd --shortlog &

echo "[entrypoint] Starting avahi-daemon..."
avahi-daemon --no-drop-root --daemonize --debug &

echo "[entrypoint] Starting Salt API..."
salt-api -d --log-level=info --log-file-level=${SALT_API_LOG_LEVEL:-warning}

echo "[entrypoint] Starting Salt Master..."

# After master is up: wait for minions, refresh mine, fire cozy/master/online
(
    sleep 15
    until salt '*' test.ping --timeout 5 --quiet 2>/dev/null; do
        sleep 5
    done
    salt '*' mine.update --timeout 10 2>/dev/null || true
    salt-run event.fire '{}' 'cozy/master/online'
    echo "[entrypoint] cozy/master/online fired"
) &

exec salt-master --log-level=info --log-file-level=${SALT_MASTER_LOG_LEVEL:-warning}
