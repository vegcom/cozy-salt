#!/bin/bash
# Managed by Salt - DO NOT EDIT MANUALLY

# Only run in interactive shells
case $- in
    *i*) ;;
    *) return 2>/dev/null ;;
esac

# Only run in login shells
case $- in
    -*) ;;
    *) return 2>/dev/null ;;
esac

# Cozy message only once
if [ -z "${__COZY_MSG_EXPORTED}" ]; then
    # ASCII art
    printf '\n🌸 %s: cozy_system_profile loaded. \033[35mSay hi to your wife.\033[0m\n' "${HOSTNAME:-localhost}"

    printf "\t\t \033[35m z \033[34m u \033[33m t \033[40m t \033[39m o \033[0m \n"
    printf "\t\t  \033[37m z \033[36m u \033[45m t \033[44m t \033[43m o \033[42m \033[0m \n"
    printf "\t\t    \033[41m z \033[45m u \033[44m t \033[43m t \033[42m o \033[41m 🌸 \033[0m \n"

    export __COZY_MSG_EXPORTED=1
fi
