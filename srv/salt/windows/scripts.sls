{% set opt_cozy = "C:\\opt\\cozy\\bin\\" %}

cozy_opt_bin:
  file.directory:
    - name: {{ opt_cozy }}
    - source: salt://windows/files/opt-cozy-bin/
    - makedirs: True
    - order: 1

cozy_opt_scripts:
  file.recurse:
    - name: {{ opt_cozy }}
    - source: salt://windows/files/opt-cozy-bin/
    - makedirs: True
    - win_owner: Administrators
    - win_inheritance: True
    - order: 0
    - require:
      - file: cozy_opt_bin
