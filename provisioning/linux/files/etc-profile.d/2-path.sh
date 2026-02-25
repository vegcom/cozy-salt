#!/bin/bash
# 2-path.sh

# Salt onedir installs go here
safe_append_path '/opt/saltstack/salt'

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
safe_append_path '/opt/cozy/bin'

# Export once, and only once
export PATH
