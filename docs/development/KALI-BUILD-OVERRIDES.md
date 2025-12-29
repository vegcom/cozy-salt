# Building on Kali Linux - Repository Overrides

When building Docker containers on a Kali Linux host, you may need to override default repository mirrors to ensure compatibility.

## Issue

Kali Linux uses non-standard package repositories that can interfere with Debian/Ubuntu/RHEL container builds. While the Dockerfiles explicitly clean inherited sources, advanced scenarios may require custom mirror configuration.

## Build Arguments

All Dockerfiles support build-time arguments to override repository mirrors:

### Ubuntu Minion & Master

```bash
docker build \
  --build-arg UBUNTU_MIRROR=<mirror-url> \
  --build-arg SECURITY_MIRROR=<security-mirror-url> \
  --build-arg UBUNTU_CODENAME=noble \
  -f Dockerfile.ubuntu-minion .
```

**Default values:**
- `UBUNTU_MIRROR=archive.ubuntu.com`
- `SECURITY_MIRROR=security.ubuntu.com`
- `UBUNTU_CODENAME=noble` (Ubuntu 24.04)

**Example for corporate proxy:**
```bash
docker build \
  --build-arg UBUNTU_MIRROR=mirror.corporate.com/ubuntu \
  --build-arg SECURITY_MIRROR=mirror.corporate.com/security \
  -f Dockerfile.ubuntu-minion .
```

### RHEL Minion

```bash
docker build \
  --build-arg RHEL_VERSION=9 \
  -f Dockerfile.rhel-minion .
```

## Using docker-compose with Build Args

Add a `.env` file or modify `docker-compose.yaml`:

```yaml
services:
  salt-minion-ubuntu-test:
    build:
      context: .
      dockerfile: Dockerfile.ubuntu-minion
      args:
        UBUNTU_MIRROR: archive.ubuntu.com
        SECURITY_MIRROR: security.ubuntu.com
        UBUNTU_CODENAME: noble
```

## Troubleshooting

### Issue: "W: Skipping acquire of configured file 'testing/binary-amd64/Packages'"

This indicates non-standard repository sources are being used. The Dockerfiles now explicitly clean these, but if you still see this:

1. **Force a fresh rebuild** (no cache):
   ```bash
   docker compose build --no-cache salt-minion-ubuntu-test
   ```

2. **Check your host sources**:
   ```bash
   cat /etc/apt/sources.list
   cat /etc/apt/sources.list.d/*
   ```

3. **Use explicit mirrors in docker-compose**:
   ```bash
   docker compose build \
     --build-arg UBUNTU_MIRROR=deb.debian.org \
     --build-arg SECURITY_MIRROR=security.debian.org \
     salt-minion-ubuntu-test
   ```

### Issue: "E: The repository 'https://download.docker.com/linux/kali kali-rolling Release' does not have a Release file"

This error appears when Kali sources leak into the container. Solutions:

1. **Rebuild with --no-cache** (recommended):
   ```bash
   make clean
   make test
   ```

2. **Explicitly remove inherited sources** before build:
   On your host (Kali), temporarily rename sources:
   ```bash
   sudo mv /etc/apt/sources.list.d /etc/apt/sources.list.d.bak
   docker compose build --no-cache
   sudo mv /etc/apt/sources.list.d.bak /etc/apt/sources.list.d
   ```

## Repository Isolation Strategy

The Dockerfiles use a **defense-in-depth** approach:

1. **Explicit cleanup**: Each Dockerfile removes `/etc/apt/sources.list.d/*` and `/etc/yum.repos.d/*`
2. **No volume mounts**: Repository configuration directories are never mounted from the host
3. **Build arguments**: Allow overriding mirrors without modifying Dockerfiles
4. **Network isolation**: Containers use internal Docker network, not host network

## Reference

- Ubuntu mirrors: https://launchpad.net/ubuntu/+cdmirrors
- Debian mirrors: https://www.debian.org/mirror/list
- Kali sources: https://docs.kali.org/deb-package-management/kali-linux-apt-sources

## Future Improvements

Potential enhancements for multi-distro builds:
- Build matrix for testing on different hosts
- Automated mirror detection
- Repository health checks before build
- Multi-stage builds with mirror selection
