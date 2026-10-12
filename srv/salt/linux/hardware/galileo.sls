# Steam Deck (Valve Galileo/Jupiter) hardware tuning
# Only targeted via top.sls compound match on manufacturer/productname grains

{#- systemd #}

etc-systemd_path:
  file.directory:
    - name: /etc/systemd
    - user: root
    - group: root
    - mode: "0755"

{#- systemd - zram #}

etc-systemd-zram-generator.conf:
  file.managed:
    - name: /etc/systemd/zram-generator.conf
    - source: salt://linux/files/etc-systemd/zram-generator.conf
    - makedirs: True
    - require:
      - file: etc-systemd_path

{#- systemd - sleep.conf #}

etc-systemd-sleep.conf.d_path:
  file.directory:
    - name: /etc/systemd/sleep.conf.d
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-sleep.conf.d-cozy-galileo.conf:
  file.managed:
    - name: /etc/systemd/sleep.conf.d/cozy.conf
    - source: salt://linux/files/etc-systemd-sleep.conf.d/cozy-galileo.conf
    - makedirs: True
    - require:
      - file: etc-systemd-sleep.conf.d_path

{#- systemd - login.d #}

etc-systemd-logind.conf.d_path:
  file.directory:
    - name: /etc/systemd/logind.conf.d
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-logind.conf.d:
  file.recurse:
    - name: /etc/systemd/logind.conf.d
    - source: salt://linux/files/etc-systemd-logind.conf.d
    - include_empty: True
    - clean: True
    - user: root
    - group: root
    - dir_mode: "0755"
    - file_mode: "0644"
    - require:
      - file: etc-systemd-logind.conf.d_path

logind_reload:
  service.running:
    - name: systemd-logind
    - onchanges:
      - file: etc-systemd-logind.conf.d

{#- systemd - system app-steam-slices.d : limits #}

etc-systemd-system-app-steam.slice.d_path:
  file.directory:
    - name: /etc/systemd/system/app-steam.slice.d/
    - user: root
    - group: root
    - mode: "0755"

etc-systemd-system-app-steam.slice.d/limits.conf:
  file.managed:
    - name: /etc/systemd/system/app-steam.slice.d/limits.conf
    - source: salt://linux/files/etc-systemd-system-app-steam.slice.d/limits.conf
    - makedirs: True
    - require:
      - file: etc-systemd-system-app-steam.slice.d_path

{#- mkinitcpio #}

etc-mkinitcpio.d_path:
  file.directory:
    - name: /etc/mkinitcpio.d
    - user: root
    - group: root
    - mode: "0755"

etc-mkinitcpio.d-linux.conf:
  file.managed:
    - name: /etc/mkinitcpio.d/linux.conf
    - source: salt://linux/files/etc-mkinitcpio.d/cozy-galileo.conf
    - makedirs: True
    - require:
      - file: etc-mkinitcpio.d_path

{#- modprobe.d #}

etc-modprobe.d_path:
  file.directory:
    - name: /etc/modprobe.d
    - user: root
    - group: root
    - mode: "0755"

etc-modprobe.d-cozy-galileo.conf:
  file.managed:
    - name: /etc/modprobe.d/cozy-galileo.conf
    - source: salt://linux/files/etc-modprobe.d/cozy-galileo.conf
    - makedirs: True
    - require:
      - file: etc-modprobe.d_path
