# Docker Socket Proxy

Deploy TCP socket proxy for Docker daemon on localhost:2375 (read-only) and 2376 (admin).

## Location

- **State**: `srv/salt/linux/docker-proxy.sls`
- **Include**: `linux.init`
- **Uses**: Docker container `tecnativa/docker-socket-proxy`

## Purpose

Expose Docker socket over TCP for:
- WSL Windows hosts accessing Linux Docker daemon
- Remote debugging and management
- Kubernetes/service mesh control plane access

## Configuration

Deployed via systemd unit: `docker-socket-proxy.service`

| Port | Type | Access |
|------|------|--------|
| 2375 | TCP | Read-only (GET, HEAD, OPTIONS only) |
| 2376 | TCP | Admin (full access, requires auth) |

## Ports Exposed

**Read-only (2375)**:
- Containers, images, volumes (list/inspect only)
- System info, events, version

**Admin (2376)**:
- Container lifecycle (create, start, stop, remove)
- Image operations (pull, push, build)
- Volume/network management

## Notes

- Requires Docker installation (`common.docker`) first
- Uses `ALLOW` list for security (whitelist approach)
- Logs to systemd: `journalctl -u docker-socket-proxy -f`
- Only enabled if Docker is present and running
