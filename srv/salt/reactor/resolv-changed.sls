{# Reactor: fired by salt/beacon/*/inotify//etc/resolv.conf #}
{# Restores managed DNS config when resolv.conf is modified externally #}

fix_resolv_{{ data['id'] }}:
  local.state.apply:
    - tgt: {{ data['id'] }}
    - arg:
      - linux.resolve
