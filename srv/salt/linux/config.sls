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

# Export git user config as environment variables for vim
git_env_vars_linux:
  cmd.run:
    - name: |
        GIT_NAME=$(git config --global user.name)
        GIT_EMAIL=$(git config --global user.email)

        BASHRC="$HOME/.bashrc"
        MARKER_START="# START: Git environment variables (managed by Salt)"
        MARKER_END="# END: Git environment variables"

        if ! grep -q "$MARKER_START" "$BASHRC" 2>/dev/null; then
          cat >> "$BASHRC" <<EOF

        $MARKER_START
        export GIT_NAME="$GIT_NAME"
        export GIT_EMAIL="$GIT_EMAIL"
        $MARKER_END
        EOF
        else
          sed -i "/$MARKER_START/,/$MARKER_END/c\\
        $MARKER_START\\
        export GIT_NAME=\"$GIT_NAME\"\\
        export GIT_EMAIL=\"$GIT_EMAIL\"\\
        $MARKER_END" "$BASHRC"
        fi
    - runas: {{ salt['pillar.get']('user:name', 'admin') }}
    - shell: /bin/bash
    - onlyif: git config --global user.name
