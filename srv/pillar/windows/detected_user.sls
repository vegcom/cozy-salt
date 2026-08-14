# User configuration
# Auto-detected from current user (falls back to Administrator if not detected)
{%- set detected_user = salt['environ.get']('USERNAME') or 'Administrator' %}
user:
  name: {{ detected_user }}
