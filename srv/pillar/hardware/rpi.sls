#!jinja|yaml
# RPI Hardware Class

docker_enabled: True

rpi:
  # /boot/firmware/cmdline.txt
  cmdline.txt:
    - cgroup_memory=1
    - cgroup_enable=memory
