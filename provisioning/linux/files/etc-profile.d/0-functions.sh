#!/bin/bash
# 0-functions.sh

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
    # FIXME: must replicate original function
    #     * stub is unsafe and untrustworthy
    :;
}

cozy_render(){
    _helper(){
        bash <<"EOF"
        set -o pipefail
        _state_output="$(salt-call -l quiet state.show_states 2>&1)" || printf '\n%s\n' "${_state_output}"  2>&1 || exit 1
        awk '/- /{gsub(/\./, "/");system("echo \"salt://"$NF".sls\" ; salt-call slsutil.renderer default_renderer=jinja \"salt://"$NF".sls\"")}'" <<<${_state_output}
EOF
    }
    _helper|fzf --literal --no-clear
}
export cozy_render


cozy_persist_shell(){
  if [ -n "$1" ];then 
    _host=${1}
    _port=${2:-22}
    while ! ssh "${_host}" ; do sleep 15 ; nc -vzw 5 "${_host}" 22 ; done
  fi
}