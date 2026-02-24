# GID ranges:
#   2000s: service groups (cozy-salt-svc, etc.)
#   3000:  cozyusers
#   3001+: user primary groups (same as UID for SMB/NFS consistency)
# System groups pinned to avoid collision with user range
groups:
  cozyusers:
    gid: 3000
  libvirt:
    gid: 2001
  docker:
    gid: 2002
  # SMB required 1000 for cozy-share
  smb:
    gid: 1000
