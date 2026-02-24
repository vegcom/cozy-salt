# Cozy SSH Configuration Deployment
# Clones vegcom/cozy-ssh to /opt/cozy/cozy-ssh, symlinks per-user
# Requires git and ssh_keys in pillar for users
# Private repo - requires SSH key with access (pillar: git:identity_file)

{% set repo_path = '/opt/cozy/cozy-ssh' %}
{% set users = salt['pillar.get']('users', {}) %}
{% set managed_users = salt['pillar.get']('managed_users', [], merge=True) %}
{% set git_identity = salt['pillar.get']('git:identity_file', '/root/.ssh/id_ed25519') %}

# # Clone cozy-ssh repo to /opt/cozy/cozy-ssh
# cozy_ssh_repo:
#   git.latest:
#     - name: git@github.com:vegcom/cozy-ssh.git
#     - target: {{ repo_path }}
#     - branch: main
#     - force_reset: True
#     - identity: {{ git_identity }}
#     - require:
#       - file: cozy_opt_dir

# # Set permissions on repo (readable by cozyusers)
# cozy_ssh_repo_perms:
#   file.directory:
#     - name: {{ repo_path }}
#     - mode: "0755"
#     - recurse:
#       - mode
#     - require:
#       - git: cozy_ssh_repo

# FIXME: need to copy not symlink
# # Per-user SSH symlinks and directories
# {% for username in managed_users %}
# {% set userdata = users.get(username, {}) %}
# {% set user_home = userdata.get('home_prefix', '/home') ~ '/' ~ username %}
# {% set user_ssh = user_home ~ '/.ssh' %}

# # Ensure {{ username }} .ssh directory exists
# {{ username }}_cozy_ssh_dir:
#   file.directory:
#     - name: {{ user_ssh }}
#     - user: {{ username }}
#     - group: {{ username }}
#     - mode: "0700"
#     - makedirs: True

# FIXME: need to copy not symlink
# # Symlink {{ username }} SSH config
# {{ username }}_ssh_config_symlink:
#   file.symlink:
#     - name: {{ user_ssh }}/config
#     - target: {{ repo_path }}/config
#     - user: {{ username }}
#     - group: {{ username }}
#     - force: True
#     - require:
#       - git: cozy_ssh_repo
#       - file: {{ username }}_cozy_ssh_dir

# FIXME: need to copy not symlink
# # Symlink {{ username }} ssh_config.d directory
# {{ username }}_ssh_config_d_symlink:
#   file.symlink:
#     - name: {{ user_ssh }}/ssh_config.d
#     - target: {{ repo_path }}/ssh_config.d
#     - user: {{ username }}
#     - group: {{ username }}
#     - force: True
#     - require:
#       - git: cozy_ssh_repo
#       - file: {{ username }}_cozy_ssh_dir

# FIXME: need to copy not symlink
# # Symlink {{ username }} scripts directory
# {{ username }}_ssh_scripts_symlink:
#   file.symlink:
#     - name: {{ user_ssh }}/scripts
#     - target: {{ repo_path }}/scripts
#     - user: {{ username }}
#     - group: {{ username }}
#     - force: True
#     - require:
#       - git: cozy_ssh_repo
#       - file: {{ username }}_cozy_ssh_dir

# FIXME: depends on copy not symlink above
# # Create {{ username }} known_hosts directory (local, not symlinked)
# {{ username }}_ssh_known_hosts_dir:
#   file.directory:
#     - name: {{ user_ssh }}/known_hosts
#     - user: {{ username }}
#     - group: {{ username }}
#     - mode: "0700"
#     - require:
#       - file: {{ username }}_cozy_ssh_dir

# FIXME: depends on copy not symlink above
# # Create {{ username }} ctrl directory for ControlMaster sockets
# {{ username }}_ssh_ctrl_dir:
#   file.directory:
#     - name: {{ user_ssh }}/ctrl
#     - user: {{ username }}
#     - group: {{ username }}
#     - mode: "0700"
#     - require:
#       - file: {{ username }}_cozy_ssh_dir

# {% endfor %}
