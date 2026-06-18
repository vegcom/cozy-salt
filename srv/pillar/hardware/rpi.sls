#!jinja|yaml
# RPI Hardware Class

host:
  capabilities:
    k3s: true
    docker: true

rpi:
  # /boot/firmware/cmdline.txt
  cmdline.txt:
    - cgroup_memory=1
    - cgroup_enable=memory
