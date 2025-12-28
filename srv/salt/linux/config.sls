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
