{% set is_container = salt['file.file_exists']('/.dockerenv') or salt['file.file_exists']('/run/.containerenv') %}


{%-  if is_container == False %}

wsdd_service:
  service.running:
  {%- if grains['os_family'] != 'Arch' %}
    - name: wsdd-server
  {%- else %}
    - name: wsdd
  {%- endif %}
    - enable: True

{%- else %}

wsdd_service_:
  test.nop:
    - name: "wsdd not enabled"

{%- endif %}
