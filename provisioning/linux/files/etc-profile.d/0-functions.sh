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