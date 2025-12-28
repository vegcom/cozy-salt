# Linux configuration
# User environment, shell setup, and system configuration

# Deploy skeleton files to /etc/skel for new users
skel_files:
  file.recurse:
    - name: /etc/skel
    - source: salt://linux/files/etc-skel
    - include_empty: True
    - clean: False

# Deploy starship profile script (installation handled by the script itself)
starship_profile:
  file.managed:
    - name: /etc/profile.d/starship.sh
    - source: salt://linux/files/etc-profile.d/starship.sh
    - mode: 755

# Deploy hardened SSH configuration
# WSL systems get WSL-specific config (Port 2222), others get standard config
{% if grains.get('kernel_release', '').find('WSL') != -1 or grains.get('kernel_release', '').find('Microsoft') != -1 %}
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://wsl/files/etc-ssh/sshd_config.d/99-hardening.conf
    - mode: 644
    - makedirs: True
{% else %}
sshd_hardening_config:
  file.managed:
    - name: /etc/ssh/sshd_config.d/99-hardening.conf
    - source: salt://linux/files/etc-ssh/sshd_config.d/99-hardening.conf
    - mode: 644
    - makedirs: True
{% endif %}
