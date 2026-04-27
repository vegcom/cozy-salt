#!jinja|yaml
# Network beacons — Linux only
# Reactor handles:
#   salt/beacon/*/network_settings/* → netinfo.collect runner
#   salt/beacon/*/inotify//etc/resolv.conf → linux.resolve state

{% if grains.get('os_family') != 'Windows' %}
beacons:
  network_settings:
    - coalesce: 30
  inotify:
    - files:
        /etc/resolv.conf:
          mask:
            - modify
            - create
            - delete
    - coalesce: 5
{% endif %}
