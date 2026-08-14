scheduled_tasks:
  wsl:
    - name: wsl_autostart
      file: windows/tasks/wsl/wsl_autostart.xml
      enabled: True
  backup:
    - name: restore_point
      file: windows/tasks/backup/restore_point.xml
      enabled: True
    - name: syncthing
      file: windows/tasks/backup/syncthing.xml
      enabled: True
  net:
    - name: tor
      file: windows/tasks/net/tor.xml
      enabled: True
    - name: shadowsocks
      file: windows/tasks/net/shadowsocks.xml
      enabled: True
    - name: tailscale
      file: windows/tasks/net/tailscale.xml
      enabled: True
    - name: ipfs
      file: windows/tasks/net/ipfs.xml
      enabled: True
  kubernetes:
    - name: docker_registry_port_forward
      file: windows/tasks/kubernetes/docker_registry_port_forward.xml
      enabled: False
    - name: ollama_port_forward
      file: windows/tasks/kubernetes/ollama_port_forward.xml
      enabled: False
    - name: open_webui_port_forward
      file: windows/tasks/kubernetes/open_webui_port_forward.xml
      enabled: False
  update:
    - name: winget_update
      file: windows/tasks/update/winget.xml
      enabled: true
