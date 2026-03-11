# Linux configuration
# User environment, shell setup, and system configuration

# NOTE: /etc/skel is now managed in linux/users.sls (must run before user.present)

etc_path:
  file.directory:
    - name: /etc/
    - user: root
    - group: root
    - mode: "0755"

etc_files:
  file.recurse:
    - name: /etc/
    - source: salt://linux/files/etc/
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_path

etc_profiled_path:
  file.directory:
    - name: /etc/profile.d
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: etc_path

etc_profiled_files:
  file.recurse:
    - name: /etc/profile.d
    - source: salt://linux/files/etc-profile.d/
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_profiled_path

etc_zsh_path:
  file.directory:
    - name: /etc/
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: etc_path

etc_zsh_files:
  file.recurse:
    - name: /etc/zsh
    - source: salt://linux/files/etc-zsh/
    - include_empty: True
    - clean: True
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_zsh_path

cozy_opt_dir:
  file.directory:
    - name: /opt/cozy
    - source: salt://linux/files/opt-cozy
    - makedirs: True
    - mode: "0775"
    - order: 1
    - recurse:
      - user
      - group

cozy_opt_bin:
  file.recurse:
    - name: /opt/cozy/bin/
    - source: salt://linux/files/opt-cozy-bin
    - include_empty: True
    - clean: False
    - dir_mode: "0775"
    - file_mode: "0774"
    - order: 0
    - require:
      - file: cozy_opt_dir

etc_systemd_path:
  file.directory:
    - name: /etc/systemd/system
    - user: root
    - group: root
    - mode: "0755"

etc_systemd_system_units:
  file.directory:
    - name: /etc/systemd/system
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: etc_systemd_path

etc_systemd_system_unit_files:
  file.recurse:
    - name: /etc/systemd/system
    - source: salt://linux/files/etc-systemd-system
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_systemd_system_units

etc_systemd_user_units:
  file.directory:
    - name: /etc/systemd/user
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: etc_systemd_path

etc_systemd_user_unit_files:
  file.recurse:
    - name: /etc/systemd/user
    - source: salt://linux/files/etc-systemd-user
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_systemd_user_units

etc_environmentd_path:
  file.directory:
    - name: /etc/systemd/user
    - user: root
    - group: root
    - mode: "0755"
    - require:
      - file: etc_systemd_path

etc_environmentd_files:
  file.recurse:
    - name: /etc/environment.d/
    - source: salt://linux/files/etc-environment.d/
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - file_mode: "0644"
    - dir_mode: "0755"
    - require:
      - file: etc_environmentd_path

# Generate banners during highstate
run_gen_motd:
  cmd.run:
    - name: /opt/cozy/bin/gen_motd.sh
    - require:
      - file: cozy_opt_bin
    - onchanges:
      - file: cozy_opt_bin

run_gen_issue:
  cmd.run:
    - name: /opt/cozy/bin/gen_issue.sh
    - require:
      - file: cozy_opt_bin
    - onchanges:
      - file: cozy_opt_bin

run_gen_issuenet:
  cmd.run:
    - name: /opt/cozy/bin/gen_issuenet.sh
    - require:
      - file: cozy_opt_bin
    - onchanges:
      - file: cozy_opt_bin
