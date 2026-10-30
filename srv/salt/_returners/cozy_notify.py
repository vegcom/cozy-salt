"""
cozy_notify returner — desktop toast after highstate/orchestrate
"""

import json
import logging
import platform
import subprocess

try:
    import pwd
except ImportError:
    pwd = None

log = logging.getLogger(__name__)

WATCHED_FUNS = {
    "state.highstate",
    "state.orch",
    "state.orchestrate",
    "state.sls",
    "state.sls_id",
}

WATCHED_SALTUTIL = [
    "saltutil.sync_all",
    "saltutil.sync_beacons",
    "saltutil.sync_clouds",
    "saltutil.sync_engines",
    "saltutil.sync_executors",
    "saltutil.sync_grains",
    "saltutil.sync_log_handlers",
    "saltutil.sync_matchers",
    "saltutil.sync_modules",
    "saltutil.sync_output",
    "saltutil.sync_outputters",
    "saltutil.sync_pillar",
    "saltutil.sync_proxymodules",
    "saltutil.sync_renderers",
    "saltutil.sync_resources",
    "saltutil.sync_returners",
    "saltutil.sync_sdb",
    "saltutil.sync_serializers",
    "saltutil.sync_states",
    "saltutil.sync_thorium",
    "saltutil.sync_tops",
    "saltutil.sync_utils",
    "saltutil.sync_wrapper",
]


def __virtual__():
    return "cozy_notify"


def _should_notify(fun: str) -> bool:
    """Return True if we want to send a notification for this function."""
    if fun in WATCHED_FUNS or fun in WATCHED_SALTUTIL:
        return True
    return False


def _parse_body(retdata, sls, success) -> str:
    """Helper to safely parse Salt returns into a readable body string."""
    body = sls

    if isinstance(retdata, dict):
        is_state_result = any("_|-" in str(k) for k in retdata.keys())

        if is_state_result:
            changed = sum(
                1 for v in retdata.values() if isinstance(v, dict) and v.get("changes")
            )
            failed = sum(
                1
                for v in retdata.values()
                if isinstance(v, dict) and not v.get("result", True)
            )
            body = f"{sls} — {changed} changed, {failed} failed"
        elif "comment" in retdata and not success:
            body = f"{sls} Error: {retdata['comment']}"
        else:
            body = f"{sls} — Finished"

    elif isinstance(retdata, list) and retdata:
        flattened = ", ".join(str(item) for item in retdata)
        body = f"{sls}: {flattened[:60]}" if len(flattened) > 60 else f"{sls}: {flattened}"  # pylint: disable=line-too-long # noqa: E501

    elif isinstance(retdata, str) and retdata:
        body = f"{sls}: {retdata[:60]}"

    return body


def returner(ret):
    fun = ret.get("fun", "")
    if not _should_notify(fun):
        return

    success = ret.get("success", False)
    minion_id = ret.get("id", "unknown")
    status = "OK" if success else "FAILED"
    title = f"Salt {status} — {minion_id}"

    fun_args = ret.get("fun_args", []) or []
    sls = fun_args[0] if fun_args else fun.split(".", 1)[-1]

    retdata = ret.get("return", {})
    body = _parse_body(retdata, sls, success)

    try:
        if platform.system() == "Windows":
            _notify_windows(title, body, ret=ret)
        else:
            _notify_linux(title, body)
    except Exception as exc:  # pylint: disable=broad-exception-caught
        log.critical("cozy_notify: notification failed: %s", exc)


def _notify_linux(title, body):
    if pwd is None:
        log.debug("cozy_notify: pwd not available (non-Unix platform)")
        return

    try:
        result = subprocess.check_output(["who", "-q"], text=True, timeout=5)
        first_line = result.split("\n", maxsplit=1)[0]
        users = list(set(first_line.split()))
    except (OSError, subprocess.SubprocessError) as exc:
        log.debug("cozy_notify: failed to run 'who -q': %s", exc)
        users = []

    for user in users:
        try:
            linux_title = title.replace("'", "'\\''")
            linux_body = body.replace("'", "'\\''")

            uid = pwd.getpwnam(user).pw_uid
            dbus_addr = f"unix:path=/run/user/{uid}/bus"
            cmd = (
                f"DBUS_SESSION_BUS_ADDRESS={dbus_addr} DISPLAY=:0 "
                f"notify-send -a Salt -i dialog-information '{linux_title}' '{linux_body}'"  # pylint: disable=line-too-long # noqa: E501
            )
            subprocess.run(
                ["sudo", "-u", user, "bash", "-c", cmd], timeout=5, check=False
            )
        except (OSError, subprocess.SubprocessError, KeyError, AttributeError) as exc:
            log.debug("cozy_notify linux %s: %s", user, exc)


def _notify_windows(title, body, ret=None):
    log.debug(
        "cozy_notify windows: Attempting notification. Title: '%s', Body: '%s'",
        title,
        body,
    )
    try:
        if ret:
            cache_path = r"C:\Windows\Temp\last_salt_run.json"
            try:
                with open(cache_path, "w", encoding="utf-8") as f:
                    json.dump(ret, f, indent=4, default=str)

                subprocess.run(
                    ["icacls.exe", cache_path, "/grant", "Users:(R,W)"],
                    capture_output=True,
                    check=False,
                )
            except Exception as cache_err:  # pylint: disable=broad-exception-caught
                log.error(
                    "cozy_notify windows: Failed to write return cache: %s", cache_err
                )

        win_title = title.replace("'", "''").replace('"', '`"')
        win_body = body.replace("'", "''").replace('"', '`"')

        ps_command = (
            f"Import-Module BurntToast; "
            f"New-BurntToastNotification -Text '{win_title}', '{win_body}'"
        )

        subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-NonInteractive",
                "-WindowStyle",
                "Minimized",
                "-Command",
                ps_command,
            ],
            timeout=10,
            check=False,
            capture_output=True,
            text=True,
        )

    except (OSError, subprocess.SubprocessError) as exc:
        log.critical("cozy_notify: notification failed: %s", exc)
