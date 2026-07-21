"""
cozy_notify returner — desktop toast after highstate/orchestrate
"""

import logging
import os
import subprocess
import tempfile

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

  retdata = ret.get("return", {})
  if isinstance(retdata, dict):
    changed = sum(
      1 for v in retdata.values() if isinstance(v, dict) and v.get("changes")
    )
    failed = sum(
      1 for v in retdata.values() if isinstance(v, dict) and not v.get("result", True)
    )
    body = f"{fun} — {changed} changed, {failed} failed"
  else:
    body = fun

  try:
    if __grains__.get("os_family") == "Windows":
      _notify_windows(title, body)
    else:
      _notify_linux(title, body)
  except Exception as exc:
    log.warning("cozy_notify: %s", exc)


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
      env = {
        **os.environ,
        "DBUS_SESSION_BUS_ADDRESS": f"unix:path=/run/user/{uid}/bus",
        "DISPLAY": ":0",
      }
      subprocess.run(
        [
          "sudo",
          "-u",
          user,
          "notify-send",
          "-a",
          "Salt",
          "-i",
          "dialog-information",
          title,
          body,
        ],
        env=env,
        timeout=5,
        check=False,
      )
    except Exception as exc:
      log.debug("cozy_notify linux %s: %s", user, exc)


def _notify_windows(title, body):
  # Write toast PS1 to temp file, run as interactive user via scheduled task
  ps_toast = f"""
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType=WindowsRuntime] | Out-Null
$xml = [Windows.Data.Xml.Dom.XmlDocument]::new()
$xml.LoadXml('<toast><visual><binding template="ToastGeneric"><text>{_esc(title)}</text><text>{_esc(body)}</text></binding></visual></toast>')
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Salt').Show(
    [Windows.UI.Notifications.ToastNotification]::new($xml)
)
"""
  with tempfile.NamedTemporaryFile(suffix=".ps1", delete=False, mode="w") as f:
    f.write(ps_toast)
    ps1_path = f.name.replace("\\", "/")

  try:
    ps_run = f"""
$user = (Get-Process explorer -IncludeUserName -ErrorAction SilentlyContinue | Select-Object -First 1).UserName
if (-not $user) {{ exit 1 }}
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -File {ps1_path}'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(2)
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName 'CozyNotify' -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName 'CozyNotify'
"""
    subprocess.run(
      ["powershell", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", ps_run],
      timeout=15,
      check=False,
    )
  except Exception as exc:
    log.debug("cozy_notify windows: %s", exc)


def _esc(s):
  return (
    s.replace("&", "&amp;")
    .replace("<", "&lt;")
    .replace(">", "&gt;")
    .replace('"', "&quot;")
  )
