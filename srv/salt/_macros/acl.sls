{%- macro cozy_acl(path, group='cozyusers', perms='rwx') %}

{{ path | replace('/', '_') | replace('.', '_') }}_acl:
  acl.present:
    - name: {{ path }}
    - acl_type: group
    - acl_name: {{ group }}
    - perms: {{ perms }}
    - recurse: True

{{ path | replace('/', '_') | replace('.', '_') }}_acl_default:
  acl.present:
    - name: {{ path }}
    - acl_type: default:group
    - acl_name: {{ group }}
    - perms: {{ perms }}

{%- endmacro %}
