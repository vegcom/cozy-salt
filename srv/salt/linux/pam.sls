{%- if grains['os_family'] == 'Debian' %}
pam_lastlog2_silent:
  file.replace:
    - name: /etc/pam.d/common-session
    - pattern: '^(session\s+optional\s+pam_lastlog2\.so)(?!\s+silent)(.*)$'
    - repl: '\1 silent\2'
{%- elif grains['os_family'] == 'Arch' %}
pam_lastlog2_silent:
  file.replace:
    - name: /etc/pam.d/system-login
    - pattern: '^(session\s+optional\s+pam_lastlog2\.so)(?!\s+silent)(.*)$'
    - repl: '\1 silent\2'
{%- endif %}
