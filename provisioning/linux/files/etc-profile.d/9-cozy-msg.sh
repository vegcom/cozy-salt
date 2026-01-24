#!/bin/bash
# 9-cozy-msg.sh

# Now do the cozy thing
if [ "${PS1-}" ]; then
  echo -e "\n🌸 ${HOSTNAME:-localhost}: cozy_system_profile loaded. \e[35mSay hi to your wife.\e[0m\n"
fi
