{% set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}


{%-  if is_container == False %}

wsdd_service:
  service.running:
    - name: wsdd
    - enable: True
    - require:
  {%- if grains['os_family'] == 'Arch' %}
      - yay: wsdd
  {%- else %}
      - pkg: wsdd-server
  {%- endif %}

{%- else %}

wsdd_service_:
  test.noop:
    - name: "wsdd not enabled"

{%- endif %}
