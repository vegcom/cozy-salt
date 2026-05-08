{# Reactor: fired when a minion comes online #}
{# Triggers API cert generation when the master (guava) connects as a minion #}

{% if data['id'] == 'salt' %}
gen_api_cert:
  runner.state.orchestrate:
    - args:
      - mods: orch.gen-api-cert
{% endif %}
