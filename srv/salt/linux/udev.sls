etc_udev_rules.d:
  file.recurse:
    - name: /etc/udev/rules.d
    - source: salt://linux/files/etc-udev-rules.d
    - include_empty: True
    - clean: False
    - user: root
    - group: root
    - dir_mode: "0755"
    - file_mode: "0644"
    - recurse:
      - user
      - group
    - order: 0
    - require:
      - file: etc_udev_rules.d_path

etc_udev_rules.d_path:
  file.directory:
    - name: /etc/udev/rules.d
    - user: root
    - group: root
    - mode: "0755"

udev_reload:
  cmd.run:
    - name: udevadm control --reload-rules
    - require:
      - file: etc_udev_rules.d_path
    - onchanges:
      - file: etc_udev_rules.d

udev_trigger:
  cmd.run:
    - name: udevadm trigger
    - require:
      - cmd: udev_reload
    - onchanges:
      - file: etc_udev_rules.d
      - cmd: udev_reload
