#!/bin/bash
# 1-paths.sh

# Build PATH the way both distros would love
safe_append_path '/usr/local/sbin'
safe_append_path '/usr/local/bin'
safe_append_path '/usr/sbin'
safe_append_path '/usr/bin'
safe_append_path '/sbin'
safe_append_path '/bin'

# Games go last — let’s not pretend we’re serious
safe_append_path '/usr/local/games'
safe_append_path '/usr/games'

# Now we ship our own jazz
safe_append_path '/opt/cozy'

# Now do the cozy thing
if [ "${PS1-}" ]; then
  echo -e "\n🌸 ${HOSTNAME:-localhost}: cozy_system_profile loaded. \e[35mSay hi to your wife.\e[0m\n"
fi
