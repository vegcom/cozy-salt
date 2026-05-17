#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# Keep Arch's append_path, but rename it
# so we don't pollute global space later
safe_append_path () {
    case ":$PATH:" in
        *:"$1":*) return ;;  # already there
        *) PATH="${PATH:+$PATH:}$1" ;;
    esac
}

safe_comp_deprecate_func() {
    # Must have at least one argument (deprecated function name)
    if [ $# -lt 1 ]; then
        return 1
    fi

    old="$1"
    new="$2"

    # Initialize tracking variable if needed
    if [ -z "$_comp_deprecate_seen" ]; then
        _comp_deprecate_seen=""
    fi

    case " $_comp_deprecate_seen " in
        *" $old "*) ;;  # already warned
        *)
            echo "bash-completion: function '$old' is deprecated; use '$new' instead" >&2
            _comp_deprecate_seen="$_comp_deprecate_seen $old"
            ;;
    esac

    return 0
}

safe_comp_deprecate_var() {
    # NIT: must replicate original function
    #     * stub is unsafe and untrustworthy
    :;
}

cozy_render(){
    _helper(){
        bash <<"EOF"
        set -o pipefail
        _state_output="$(sudo salt-call -l quiet state.show_states 2>&1)" || printf '\n%s\n' "${_state_output}"  2>&1 || exit 1
        awk '/- /{gsub(/\./, "/");system("echo \"salt://"$NF".sls\" ; sudo salt-call slsutil.renderer default_renderer=jinja \"salt://"$NF".sls\"")}'" <<<${_state_output}
EOF
    }
    _helper|fzf --literal --no-clear
}


cozy_persist_shell(){
	# Persist a shell a in a very lazy way
  if [ -n "$1" ];then
    _host=${1}
    _port=${2:-22}
    while ! ssh "${_host}" ; do sleep 15 ; nc -vzw 5 "${_host}" "${_port}" ; done
  fi
}

gclean() {
  # Marker text to stop at; default stays your original
  __marker="${1}"

  if [ -z "${__marker}" ];then
    echo "Usage: gclean <marker>"
    return 1
  fi

  _MARK="$__marker" git filter-repo --force --message-callback '
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
  if [ -d "${PWD}/.git" ] ; then
    _name="$(basename "${PWD:-$(pwd)}")"
    tmux new -s "${_name}"
  fi
}

cozy_boot(){
	__cozy_boot_help(){
		echo "last-boot - time of last boot (epoch)"
	}
  __cozy_boot_last_boot(){
    # uptime - epoch == last boot time
    awk '{print int(systime() - $1)}' /proc/uptime || return 1
  }
  case $1 in
    last-boot) __cozy_boot_last_boot;;
		*) __cozy_boot_help;;
  esac
}
