#!/bin/sh
# Managed by Salt - DO NOT EDIT MANUALLY

# Now do the cozy thing

if [ -b "${__COZY_MSG_EXPORTED}" ];then
  printf '\n🌸 %s: cozy_system_profile loaded. \e[35mSay hi to your wife.\e[0m\n' "${HOSTNAME:-localhost}"
  export __COZY_MSG_EXPORTED=1
fi
printf "\t\t \e[35m z \e[34m u \e[33m t \e[40m t \e[39m o \e[38m \e[0m \n"
printf "\t\t  \e[37m z \e[36m u \e[45m t \e[44m t \e[43m o \e[42m \e[0m \n"
printf "\t\t    \e[41m z \e[45m u \e[44m t \e[43m t \e[42m o \e[41m 🌸 \e[0m \n"
