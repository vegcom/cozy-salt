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
  elif [ -f "${preload_dir}/${minion_id}" ]; then
      pending_key="${preload_dir}/${minion_id}"
  else
      echo "[entrypoint:${__l_name}] INFO: ${preauth_dir}/${minion_id} missing (no preload fallback either)"
      pending_key=""
  fi
  echo "[entrypoint:${__l_name}] DEBUG: pending_key '${pending_key}'.."
  if [ -z "${pending_key}" ]; then
      echo "[entrypoint:${__l_name}] WARNING: No valid pending/preload target for '${minion_id}', skipping pin"
  fi


  echo "[entrypoint:${__l_name}] INFO: Selected key '${known_good_key}'.."

  # Copy ${minion_pki}/minion.pub to ${preauth_dir}/${minion_id}
  if [ -f "${known_good_key}" ]; then

    # Copy ${minion_pki}/minion.pub to ${preload_dir}/${minion_id}
    if ! cmp -s "${known_good_key}" "${pending_key}" 2>/dev/null; then
      echo "[entrypoint:${__l_name}] INFO: pinning known-good key from ${known_good_key} to ${preload_dir}/"
      if [ -f "${preauth_dir}/${minion_id}" ]; then
          pending_key="${preauth_dir}/${minion_id}"
      else
          echo "... missing: ${pending_key}.."   # still empty
      fi
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

  echo "[entrypoint:${__l_name}] INFO: restarting salt-minion..."
  pkill -f salt-minion || true
  salt-minion --disable-keepalive --log-level="${SALT_MINION_LOG_LEVEL:-warning}" --log-file-level="${SALT_MINION_LOG_FILE_LEVEL:-warning}" 2>/dev/null

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
  attempt=0
  max_attempts=12   # ~2 minutes of retries

  while [[ -z "$valid_key" && $attempt -lt $max_attempts ]]; do
      for candidate in "${candidates[@]}"; do
          if [[ -f "$candidate" ]]; then
              echo "[entrypoint:${__l_name}] DEBUG: Testing candidate $candidate (attempt $((attempt+1)))"

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

      attempt=$((attempt + 1))
      sleep 10
  done

  if [[ -n "$valid_key" ]]; then
      echo "[entrypoint:${__l_name}] INFO: Using valid key from $valid_key"
      cp -f "$valid_key" "${minions_dir}/salt"
      chown salt:salt "${minions_dir}/salt" 2>/dev/null || true
      chmod 644 "${minions_dir}/salt" 2>/dev/null || true

      # Clean up the other locations for "salt"
      rm -f "${preauth_dir}/salt" "${denied_dir}/salt" 2>/dev/null || true
  else
      echo "[entrypoint:${__l_name}] WARNING: No working key found for 'salt' after $max_attempts attempts"
  fi

  # Wait until the local minion is happy
  until (salt-call test.ping --hard-crash --output='json' --timeout=5 --log-level='quiet' 2>/dev/null 1>/dev/null); do
      printf '[entrypoint:%s] DEBUG: Waiting for local minion to be happy...\n' "${__l_name}"
      sleep 5
  done

  # Final cleanup + prefer preload where appropriate
  find "${minions_dir}" -mindepth 1 -maxdepth 1 -type f 2>/dev/null | while read -r key_file; do
      _id="$(basename "${key_file}")"

      [[ -f "${denied_dir}/${_id}" ]] && rm -f "${denied_dir}/${_id}"
      [[ -f "${preauth_dir}/${_id}" ]] && rm -f "${preauth_dir}/${_id}"

      # Only overwrite from preload if we don't already have a working key
      # (for "salt" we are especially careful)
      if [[ -f "${preload_dir}/${_id}" ]]; then
          if [[ "$_id" != "salt" ]] || [[ -z "$valid_key" ]]; then
              echo "[entrypoint:${__l_name}] DEBUG: Preferring preload version for ${_id}"
              cp -vf "${preload_dir}/${_id}" "${minions_dir}/${_id}"
          fi
      fi
  done

  salt '*' mine.update --timeout 10 --output quiet 1>/dev/null 2>/dev/null || true
  salt-run event.fire '{}' 'cozy/master/online' 2>/dev/null || salt-run state.orchestrate orch.gen-api-cert
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
