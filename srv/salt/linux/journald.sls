etc-systemd-journald.conf.d_path:
  file.directory:
    - name: /etc/systemd/journald.conf.d
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-journald.conf.d:
  file.recurse:
    - name: /etc/systemd/journald.conf.d
    - source: salt://linux/files/etc-systemd-journald.conf.d
    - include_empty: True
    - clean: True
    - user: root
    - group: root
    - dir_mode: "0755"
    - file_mode: "0644"
    - recurse:
      - user
      - group
    - order: 0
    - require:
      - file: etc-systemd-journald.conf.d_path

journald_reload:
  service.running:
    - name: systemd-journald
    - require:
      - file: etc-systemd-journald.conf.d_path
    - onchanges:
      - file: etc-systemd-journald.conf.d
