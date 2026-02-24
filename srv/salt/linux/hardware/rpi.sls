{%- set cmdline_params = salt['pillar.get']('rpi:cmdline.txt', []) %}

# /boot/firmware/cmdline.txt is a single line — idempotent param injection
# pattern uses negative lookahead: only matches (and replaces) if param absent
{% for param in cmdline_params %}
rpi_cmdline_{{ param | replace('=', '_') }}:
  file.replace:
    - name: /boot/firmware/cmdline.txt
    - pattern: "^((?!.*{{ param }}).*)$"
    - repl: '\1 {{ param }}'
    - flags:
      - MULTILINE
{% endfor %}
