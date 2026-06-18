{# Reactor: fired by salt/beacon/*/network_settings/* #}
{# Collects netinfo from the minion and writes /srv/data/network/{id}.json #}

collect_netinfo_{{ data['id'] }}:
  runner.netinfo.collect:
    - minion_id: {{ data['id'] }}
