#!/usr/bin/env bash

# Generate master keys if they don't exist (CI environment)
# Local dev bind-mounts keys from host, so this only runs in CI
# Note: Docker creates empty directories when bind-mounting non-existent files

set -e

minion_id="salt"

known_good_key=""
pending_key=""

master_pki="/etc/salt/pki/master"
minion_pki="/etc/salt/pki/minion"

minion_conf="/etc/salt/minion"
minion_conf_d="/etc/salt/minion.d"

autoreject_file="/etc/salt/autosign.d/autoreject_file.conf"
autosign_file="/etc/salt/autosign.d/autosign_file.conf"

minions_dir="${master_pki}/minions"
preauth_dir="${master_pki}/minions_pre"
preload_dir="${master_pki}/minions_preload"

denied_dir="${master_pki}/minions_denied"
autosign_dir="${master_pki}/minions_autosign"

minion_preload_dir="${minion_pki}/minions_preload"

__l_name='main'
__s_cert='/etc/salt/pki/api/salt.crt'

# Path management

__master_paths=(
  "${autosign_dir}"
  "${denied_dir}"
  "${minions_dir}"
  "${preauth_dir}"
  "${preload_dir}"
)

__minion_paths=(
  "${minion_pki}"
  "${minion_conf_d}"
)

(
  __l_name='path_prep'
  for _path in ${__master_paths[@]} ${__minion_paths[@]}; do
    if [ -n "${_path}" ]; then
      if [ -f "${_path}" ] || [ ! -d "${_path}" ]; then
        echo "[entrypoint:${__l_name}] DEBUG: Path cleaned '${_path}'"
        rm "${_path}" 2>/dev/null || true
      fi
      if [ ! -d "${_path}" ]; then
        echo "[entrypoint:${__l_name}] DEBUG: Creating path '${_path}'"
        mkdir -p "${_path}" || true
      else
        echo "[entrypoint:${__l_name}] DEBUG: Okay path '${_path}'"
      fi
    fi
  done
)

# --- Special handling for the master's own minion ("salt") ---
if [ "$minion_id" = "salt" ]; then
  echo "[entrypoint] INFO: Ensuring clean key state for master's own minion (id: salt)"

  # Remove any bad state that causes it to get stuck in denied/pre
  rm -f "${minions_dir}/salt" \
    "${preauth_dir}/salt" \
    "${denied_dir}/salt" \
    2>/dev/null || true

  # If we have a known good key in preload, use that.
  # Otherwise fall back to whatever the minion currently has.
  if [ -f "${preload_dir}/salt" ]; then
    echo "[entrypoint] INFO: Seeding salt key from preload"
    cp -f "${preload_dir}/salt" "${minions_dir}/salt"
    chown salt:salt "${minions_dir}/salt" 2>/dev/null || true
    chmod 644 "${minions_dir}/salt" 2>/dev/null || true
  elif [ -f "${minion_pki}/minion.pub" ]; then
    echo "[entrypoint] INFO: Seeding salt key from current minion key"
    cp -f "${minion_pki}/minion.pub" "${minions_dir}/salt"
    chown salt:salt "${minions_dir}/salt" 2>/dev/null || true
    chmod 644 "${minions_dir}/salt" 2>/dev/null || true
  fi
fi

# Generate master key

if [[ ! -f "${master_pki}/master.pem" ]]; then
  echo "[entrypoint:${__l_name}] INFO: Generating master keys"
  # Remove empty directories Docker may have created from missing bind mounts
  [[ -d "${master_pki}/master.pem" ]] && rmdir "${master_pki}/master.pem" 2>/dev/null || true
  [[ -d "${master_pki}/master.pub" ]] && rmdir "${master_pki}/master.pub" 2>/dev/null || true
  openssl genrsa -out "${master_pki}/master.pem" 4096 2>/dev/null
  openssl rsa -in "${master_pki}/master.pem" -pubout -out "${master_pki}/master.pub" 2>/dev/null
  chmod 600 "${master_pki}/master.pem"
  chmod 644 "${master_pki}/master.pub"
  chown -R salt:salt "${master_pki}"
  echo "  + Generated master.pem and master.pub"
else
  echo "[entrypoint:${__l_name}] DEBUG: Skipping generating master keys"
fi

# Set cozy-salt-svc password for SaltGUI PAM auth

if [[ -n ${SALT_API_SVC_PASS} ]]; then
  echo "cozy-salt-svc:${SALT_API_SVC_PASS}" | chpasswd
  echo "[entrypoint:${__l_name}] INFO: cozy-salt-svc password set"
else
  echo "[entrypoint:${__l_name}] WARNING: SALT_API_SVC_PASS not set — SaltGUI login will fail"
fi

# minion config

echo "[entrypoint:${__l_name}] INFO: Configuring master as local minion..."
mkdir -p /etc/salt/minion.d
echo "master: localhost" >/etc/salt/minion.d/master.conf
echo "id: salt" >/etc/salt/minion.d/id.conf

# Auth

echo "[entrypoint:${__l_name}] INFO: Writing master aclAuth config..."
if [ ! -d /etc/salt/autosign.d ]; then
  mkdir -p /etc/salt/autosign.d
  touch ${autosign_file}
  touch ${autoreject_file}
fi

# Sqlite
# TODO: addapt for respective returner schema, present state broken

echo "[entrypoint:${__l_name}] DEBUG: Initialising sqlite3 returner schema..."
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
else:
    os.unlink(tmp)

"
chown salt:salt /srv/data/sqlite/salt_returns.db 2>/dev/null || true

# network discovery

echo "[entrypoint:${__l_name}] INFO: Starting wsdd..."
wsdd --shortlog &

echo "[entrypoint:${__l_name}] INFO: Starting avahi-daemon..."
avahi-daemon --no-drop-root --daemonize --debug &

# salt-minion

(

  __l_name='client'

  echo "[entrypoint:${__l_name}] INFO: Starting Salt Ninion service.."
  until salt-minion --disable-keepalive --log-level="${SALT_MINION_LOG_LEVEL:-warning}" --log-file-level="${SALT_MINION_LOG_FILE_LEVEL:-warning}" 2>/dev/null; do
    sleep 10
    echo "[entrypoint:${__l_name}] INFO: Restarting salt-minion.."
    pkill -f salt-minion
  done

  echo "[entrypoint:${__l_name}] INFO: Reinit master minion key from known local key.."

  # Evaluate for existing valid keys
  if [ -f "${preauth_dir}/${minion_id}" ]; then
    pending_key="${preauth_dir}/${minion_id}"
  else
    echo "[entrypoint:${__l_name}] INFO: ${preauth_dir}/${minion_id} missing: ${pending_key}.."
  fi
  echo "[entrypoint:${__l_name}] DEBUG: pending_key '${pending_key}'.."

  if [ -f "${preload_dir}/${minion_id}" ]; then
    known_good_key="${preload_dir}/${minion_id}"
  else
    if [ -f "${minion_pki}/minion.pub" ]; then
      known_good_key="${minion_pki}/minion.pub"
    fi
  fi

  echo "[entrypoint:${__l_name}] INFO: Selected key '${known_good_key}'.."

  # Copy ${minion_pki}/minion.pub to ${preauth_dir}/${minion_id}
  if [ -f "${known_good_key}" ]; then

    # Copy ${minion_pki}/minion.pub to ${preload_dir}/${minion_id}
    if ! cmp -s "${known_good_key}" "${pending_key}" 2>/dev/null; then
      echo "[entrypoint:${__l_name}] INFO: pinning known-good key from ${known_good_key} to ${preload_dir}/"
      cp -v ${known_good_key} "${pending_key}"
    else
      echo "[entrypoint:${__l_name}] INFO: not pinning key from ${known_good_key} to ${preload_dir}/"
    fi

    # Copy ${minion_pki}/minion.pub to ${preauth_dir}/${minion_id}
    if [[ -f ${pending_key} ]]; then
      if cmp -s "${known_good_key}" "${pending_key}" 2>/dev/null; then
        echo "[entrypoint:${__l_name}] INFO: pending key matches known-good key; accepting for id 'salt'"
        cp -v "${pending_key}" ${master_pki}/minions/salt
        chown salt:salt ${master_pki}/minions/salt
        chmod 644 ${master_pki}/minions/salt
      else
        echo "[entrypoint:${__l_name}] WARNING: pending key for id '${minion_id}' does not match known-good key; refusing to accept"
      fi
    else
      echo "[entrypoint:${__l_name}] WARNING: ${pending_key} not found; cannot accept key for id '${minion_id}' yet"
    fi
  else
    echo "[entrypoint:${__l_name}] WARNING: no known-good local key found at ${known_good_key}"
  fi

) &

# salt key handler

(
  __l_name='key'
  echo "[entrypoint:${__l_name}] INFO: prep minion keys"

  candidates=(
    "${preload_dir}/salt"
    "${preauth_dir}/salt"
    "${minion_pki}/minion.pub"
  )

  valid_key=""

  # Keep trying candidates until we find one that actually works
  # (this will naturally wait for the master to come up)
  while [[ -z $valid_key ]]; do
    for candidate in "${candidates[@]}"; do
      if [[ -f $candidate ]]; then
        echo "[entrypoint:${__l_name}] DEBUG: Testing candidate $candidate"

        cp -f "$candidate" "${minions_dir}/salt" 2>/dev/null || true
        chown salt:salt "${minions_dir}/salt" 2>/dev/null || true
        chmod 644 "${minions_dir}/salt" 2>/dev/null || true

        if salt-call test.ping --hard-crash --output=quiet --timeout=5 &>/dev/null; then
          echo "[entrypoint:${__l_name}] INFO: Candidate works: $candidate"
          valid_key="$candidate"
          break 2
        else
          echo "[entrypoint:${__l_name}] DEBUG: Candidate failed: $candidate"
        fi
      fi
    done

    sleep 8
  done

  if [[ -n $valid_key ]]; then
    echo "[entrypoint:${__l_name}] INFO: Using valid key from $valid_key"
    cp -f "$valid_key" "${minions_dir}/salt"
    chown salt:salt "${minions_dir}/salt" 2>/dev/null || true
    chmod 644 "${minions_dir}/salt" 2>/dev/null || true

    rm -f "${preauth_dir}/salt" "${denied_dir}/salt" 2>/dev/null || true
  else
    echo "[entrypoint:${__l_name}] WARNING: No working key found for 'salt'"
  fi

  # Wait for local minion to be happy, then do general cleanup
  until (salt-call test.ping --hard-crash --output='json' --timeout=5 --log-level='quiet' 2>/dev/null 1>/dev/null); do
    sleep 10
  done

  # Import any pre-generated keys that were shipped in the minion's own preload dir
  # (files named like "salt.pub", "rhel-test.pub", etc.)
  if [ -d "${minion_preload_dir}" ]; then
    find "${minion_preload_dir}" -mindepth 1 -maxdepth 1 -type f -name '*.pub' 2>/dev/null | while read -r pub_file; do
      _id="$(basename "${pub_file}" .pub)"
      dest="${preload_dir}/${_id}"

      if [ ! -f "${dest}" ]; then
        echo "[entrypoint:${__l_name}] INFO: Importing pre-generated key for ${_id} from minion preload"
        cp -vf "${pub_file}" "${dest}"
      else
        echo "[entrypoint:${__l_name}] DEBUG: ${_id} already exists in preload, skipping minion preload import"
      fi
    done
  fi

  find "${minions_dir}" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | while read -r key_file; do

    _id="$(basename "${key_file}")"

    # Clean denied
    [[ -f "${denied_dir}/${_id}" ]] && rm -f "${denied_dir}/${_id}"

    # Clean pending/preauth
    [[ -f "${preauth_dir}/${_id}" ]] && rm -f "${preauth_dir}/${_id}"

    # If we have a version in preload, prefer it in minions
    if [[ -f "${preload_dir}/${_id}" ]]; then
      cp -vf "${preload_dir}/${_id}" "${minions_dir}/${_id}"
    fi
  done

  salt '*' mine.update --timeout 10 --output quiet 1>/dev/null 2>/dev/null || true
  salt-run event.fire '{}' 'cozy/master/online'
  echo "[entrypoint:${__l_name}] INFO: cozy/master/online fired"

  # salt bus
  (
    __l_name='bus'
    until (salt-run state.event | while read -r tag data; do printf '[entrypoint:%s] DEBUG: "%s" %s..\n' "${__l_name}" "${tag}" "${data}"; done); do
      echo "[entrypoint:${__l_name}] WARNING: Waiting for 'state.event' to attach"
      sleep 10
    done
    echo "[entrypoint:${__l_name}] DEBUG: Attached to 'state.event'"
  ) &

) &

# salt-api
(
  __l_name='api'
  until (test -f ${__s_cert}); do
    sleep 15
    echo "[entrypoint:${__l_name}] WARNING: API Startup holding, pending ${__s_cert}"
  done
  echo "[entrypoint:${__l_name}] INFO: Attached to 'state.event'.."
  salt-api --log-level="${SALT_API_LOG_LEVEL:-warning}" --log-file-level="${SALT_API_LOG_LEVEL_FILE:-warning}"
) &

# salt master

echo "[entrypoint:${__l_name}] INFO: Starting Salt Master..."
exec salt-master --log-level="${SALT_MASTER_LOG_LEVEL:-warning}" --log-file-level="${SALT_MASTER_LOG_FILE_LEVEL:-warning}"
