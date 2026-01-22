#!/bin/bash
# ~/.bashrc :  Managed by salt

gclean() {
  # Marker text to stop at; default stays your original
  local marker="${1}"

  if [[ -z ${marker} ]];then
    echo "Usage: gclean <marker>"
    return 1
  fi

  _MARK="$marker" git filter-repo --force --message-callback '
import os

marker = os.environ.get("_MARK", "").encode()

lines = message.split(b"\n")
cleaned = []

for l in lines:
    if marker and marker in l:
        break
    cleaned.append(l)

return b"\n".join(cleaned)
'
}

t(){
  if [[ -d ${PWD}/.git ]] ; then
    tmux new -s "$(basename "${PWD}/")"
  fi
}
