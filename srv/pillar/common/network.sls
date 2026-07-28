#!jinja|yaml
# Network beacons — Linux only
# Reactor handles:
#   salt/beacon/*/network_settings/* → netinfo.collect runner
#   salt/beacon/*/inotify//etc/resolv.conf → linux.resolve state

# Moved to states, pillar does not like watch beacons
