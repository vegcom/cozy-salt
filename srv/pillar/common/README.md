{# djlint:off #}

# srv/pillar/common/user.sls
#
#

# Common user configuration metadata (example)
# Individual user definitions are in srv/pillar/users/*.sls
# This file contains only managed_users list and global tokens

# Managed users list - users that get provisioned and dotfiles deployed
# Individual user configs defined in srv/pillar/users/{username}.sls
SALT_CI: True

managed_users:
  - demo_user
  - demo_admin

# SMB mounts for users (shared git repo, etc.)
# smb:
#   git_share:
#     device: //nas.local/git
#     mountpoint: git  # relative to user home
#     fstype: cifs
#     opts: vers=3.0,soft,rw
#     credentials_path: /etc/samba/creds


# srv/pillar/common/network.sls
#
#

# Network Configuration
# DNS, hosts, and network-level settings for all platforms

# Moving to srv/pillar/secrets/network.sls
network:
  # DNS configuration (for bare metal/VMs, skipped in containers)
  dns:
    search_domain: local
    nameservers:
      - 10.0.0.1
      - 1.1.1.1
      - 1.0.0.1

  # Hosts file entries for network services
  # Per-host overrides supported via pillar merge (e.g. localhost for self)
  hosts:

    unifi:
      comment: UniFi Controller
      ips:
        - 10.0.0.1
      names:
        - unifi
        - unifi.local
        - gw
        - gw.local

    cozy-share:
      comment: SMB / NAS share
      ips:
        - 10.0.0.200
      names:
        - cozy-share
        - cozy-share.local

    salt:
      ips:
        - 10.0.0.220
      names:
        - salt
        - salt.local
        - salt.localdomain



# srv/pillar/common/scheduler.sls
#
#
# Salt Scheduler Pillar Configuration
# Define periodic jobs for minions via the Salt scheduler
#
# Usage:
#   Define schedule jobs in your pillar data:
#
#   schedule:
#     job_name:
#       function: state.sls
#       seconds: 3600
#       args:
#         - state_name
#
#   Supported time specifications:
#     - seconds/minutes/hours/days: interval-based
#     - cron: cron expression (requires python-croniter)
#     - when: specific time (5:00pm)
#     - start/end: time range
#
# Examples:
#   Run state.highstate every 24 hours:
#     schedule:
#       daily_update:
#         function: state.highstate
#         hours: 24
#
#   Run every 15 minutes:
#     schedule:
#       frequent_check:
#         function: state.sls
#         cron: '*/15 * * * *'
#         args:
#           - my.state
#
#   Run with splay (randomized start):
#     schedule:
#       update_with_splay:
#         function: state.sls
#         seconds: 300
#         args: [my.state]
#         splay:
#           start: 10
#           end: 15

schedule: {}
