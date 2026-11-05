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

autosign_grains_dir="/etc/salt/autosign_grains"

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

# Sync baked-in minion preload keys (ephemeral, refreshed every image build)
# into the master's volumed preload dir (persistent across container recreate).
# Without this, master_pki/minions_preload rots with stale keys from the
# first-ever boot of the volume, while minion_pki/minions_preload always
# reflects the current image. CI rebuilds would then pin minions to keys
# that no longer match what's actually baked into the minion images.

  (
    __l_name='preload_sync'
    if [ -d "${minion_preload_dir}" ]; then
      for _pub in "${minion_preload_dir}"/*.pub; do
        [ -f "${_pub}" ] || continue
        _id="$(basename "${_pub}" .pub)"
        _dest="${preload_dir}/${_id}"
        if ! cmp -s "${_pub}" "${_dest}" 2>/dev/null; then
          echo "[entrypoint:${__l_name}] INFO: refreshing stale preload key for '${_id}'"
          cp -f "${_pub}" "${_dest}"
          chmod 644 "${_dest}"
        else
          echo "[entrypoint:${__l_name}] DEBUG: preload key for '${_id}' already current"
        fi
      done
    else
      echo "[entrypoint:${__l_name}] WARNING: ${minion_preload_dir} missing, nothing to sync"
    fi
  )

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

find /etc/salt/pki/master/*/salt -delete

echo "[entrypoint:${__l_name}] INFO: Configuring master as local minion"
mkdir -p /etc/salt/minion.d
echo "master: localhost" >/etc/salt/minion.d/master.conf
echo "id: salt" >/etc/salt/minion.d/id.conf
echo "autosign_grains:" >/etc/salt/minion.d/autosign_grains.conf
echo "  - uuid" >>/etc/salt/minion.d/autosign_grains.conf

# Autosign via grains (UUID)
# The master's own minion identity is pinned to its hardware/container UUID
# instead of key-pinning. grains.get works --local pre-boot (reads DMI/product
# UUID directly), so we can stamp the expected value before salt-master even
# starts. On auth, the minion sends its uuid grain and the master compares it
# against this file; match -> auto-accept, no preauth/preload key juggling.
# https://docs.saltproject.io/en/latest/topics/tutorials/autoaccept_grains.html

echo "[entrypoint:${__l_name}] INFO: Stamping autosign_grains for master's own minion (uuid)"
mkdir -p "${autosign_grains_dir}"
# FIXME: When moving to python, just use json
master_uuid="$(salt-call --local --out=newline_values_only grains.get uuid --output=txt|awk '{print $NF}')"
if [ -n "${master_uuid}" ]; then
  echo "${master_uuid}" >"${autosign_grains_dir}/uuid"
  chown salt:salt "${autosign_grains_dir}/uuid"
  chmod 644 "${autosign_grains_dir}/uuid"
  echo "[entrypoint:${__l_name}] INFO: autosign_grains/uuid = ${master_uuid}"
else
  echo "[entrypoint:${__l_name}] WARNING: Could not read uuid grain; autosign_grains fallback unavailable"
fi

# Auth

echo "[entrypoint:${__l_name}] INFO: Writing master aclAuth config"
if [ ! -d /etc/salt/autosign.d ]; then
  mkdir -p /etc/salt/autosign.d
  touch ${autosign_file}
  touch ${autoreject_file}
fi

# Sqlite
# TODO: addapt for respective returner schema, present state broken

echo "[entrypoint:${__l_name}] DEBUG: Initialising sqlite3 returner schema"
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
(
  __l_name='net'
  echo "[entrypoint:${__l_name}] INFO: Starting wsdd"
  wsdd --shortlog &

  echo "[entrypoint:${__l_name}] INFO: Starting avahi-daemon"
  avahi-daemon --no-drop-root --daemonize --debug &
)

# salt-minion
(
  __l_name='client'

  echo "[entrypoint:${__l_name}] INFO: Starting Salt Ninion service"
  until salt-minion --disable-keepalive --log-level="quiet" --log-file-level="quiet" 2>/dev/null; do
    echo "[entrypoint:${__l_name}] WARNING: salt-minion restarting"
    sleep 5
  done
(
  # fires after minion ready
  __l_name='client:event'
  sleep 10
  salt-run state.orchestrate orch.gen-api-cert
  salt '*' mine.update --timeout 10 --output quiet 1>/dev/null 2>/dev/null || true
  echo "[entrypoint:${__l_name}] INFO: state.orchestrate orch.gen-api-cert submitted"
) &

  salt-minion --log-level="${SALT_MINION_LOG_LEVEL:-warning}" --log-file-level="${SALT_MINION_LOG_FILE_LEVEL:-warning}" 2>/dev/null

) &

# salt key handler
(
  __l_name='key'

  # Wait until the local minion is happy
  until (salt-call test.ping --hard-crash --output='json' --timeout=5 --log-level='quiet' 2>/dev/null 1>/dev/null); do
      printf '[entrypoint:%s] DEBUG: Waiting for local minion to be happy\n' "${__l_name}"
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

) &

# salt-api
(
  # wait until cert has landed
  # depends on: event
  __l_name='api'
  until (test -f ${__s_cert}); do
    sleep 15
    echo "[entrypoint:${__l_name}] WARNING: API Startup holding, pending ${__s_cert}"
  done
  echo "[entrypoint:${__l_name}] INFO: Attached to 'state.event'"
  # log-level: depr notice
  salt-api --log-level="${SALT_API_LOG_LEVEL:-warning}" --log-file-level="${SALT_API_LOG_LEVEL_FILE:-warning}"
) &

# salt bus
(
  __l_name='bus'
  until (salt-run state.event | while read -r tag data; do printf '[entrypoint:%s] DEBUG: "%s" %s\n' "${__l_name}" "${tag}" "${data}"; done); do
    echo "[entrypoint:${__l_name}] WARNING: Waiting for 'state.event' to attach"
    sleep 10
  done
  echo "[entrypoint:${__l_name}] DEBUG: Attached to 'state.event'"
) &

# salt master

echo "[entrypoint:${__l_name}] INFO: Starting Salt Master"
exec salt-master --log-level="${SALT_MASTER_LOG_LEVEL:-warning}" --log-file-level="${SALT_MASTER_LOG_FILE_LEVEL:-warning}"
