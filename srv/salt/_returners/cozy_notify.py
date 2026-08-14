"""
cozy_notify returner — desktop toast after highstate/orchestrate
"""

import logging
import platform
import subprocess

log = logging.getLogger(__name__)

WATCHED_FUNS = {"state.highstate", "state.orchestrate", "state.sls"}


def __virtual__():
    return "cozy_notify"


def returner(ret):
    fun = ret.get("fun", "")
    if fun not in WATCHED_FUNS:
        return

    success = ret.get("success", False)
    minion_id = ret.get("id", "unknown")
    status = "OK" if success else "FAILED"
    title = f"Salt {status} — {minion_id}"

    fun_args = ret.get("fun_args", [])
    sls = fun_args[0] if fun_args else "highstate"

    retdata = ret.get("return", {})
    if isinstance(retdata, dict):
        changed = sum(
            1 for v in retdata.values() if isinstance(v, dict) and v.get("changes")
        )
        failed = sum(
            1
            for v in retdata.values()
            if isinstance(v, dict) and not v.get("result", True)
        )
        body = f"{sls} — {changed} changed, {failed} failed"
    else:
        body = sls

    try:
        if platform.system() == "Windows":
            _notify_windows(title, body)
        else:
            _notify_linux(title, body)
    except Exception as exc:
        log.critical("cozy_notify: notification failed: %s", exc)


def _notify_linux(title, body):
    import pwd

    try:
        result = subprocess.check_output(["who", "-q"], text=True, timeout=5)
        users = list(set(result.split("\n")[0].split()))
    except Exception:
        users = []

    for user in users:
        try:
            uid = pwd.getpwnam(user).pw_uid
            dbus_addr = f"unix:path=/run/user/{uid}/bus"
            cmd = (
                f"DBUS_SESSION_BUS_ADDRESS={dbus_addr} DISPLAY=:0 "
                f"notify-send -a Salt -i dialog-information '{title}' '{body}'"
            )
            subprocess.run(
                ["sudo", "-u", user, "bash", "-c", cmd], timeout=5, check=False
            )
        except Exception as exc:
            log.debug("cozy_notify linux %s: %s", user, exc)


def _notify_windows(title, body):
    try:
        subprocess.run(
            [
                "powershell",
                "-NonInteractive",
                "-WindowStyle",
                "Hidden",
                "-Command",
                f"New-BurntToastNotification -Text '{_esc(title)}', '{_esc(body)}'",
            ],
            timeout=10,
            check=False,
        )
    except Exception as exc:
        log.critical("cozy_notify windows: %s", exc)


def _esc(s):
    return (
        s.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )
