#!jinja|yaml
# Reactor: Windows Health Check Failure
# Triggers emergency-maint.ps1 when health-check fires failure event

{% set data = data or {} %}
{% set minion_id = data.get('minion', data.get('id', '')) %}

{% if minion_id %}
windows_emergency_maintenance:
  cmd.script:
    - tgt: {{ minion_id }}
    - arg:
      - salt://provisioning/windows/files/opt-cozy/emergency-maint.ps1
    - kwarg:
        shell: powershell
{% endif %}
