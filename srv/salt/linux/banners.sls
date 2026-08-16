# Generate banners during highstate
run_gen_motd:
  cmd.run:
    - name: opt_cozy_bin/gen_motd.sh
    - onchanges:
      - file: opt_cozy_bin_files

run_gen_issue:
  cmd.run:
    - name: opt_cozy_bin/gen_issue.sh

    - onchanges:
      - file: opt_cozy_bin_files

run_gen_issuenet:
  cmd.run:
    - name: opt_cozy_bin/gen_issuenet.sh

    - onchanges:
      - file: opt_cozy_bin_files
