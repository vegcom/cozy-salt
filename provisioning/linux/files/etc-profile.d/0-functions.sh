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

# Export once, and only once
export PATH
