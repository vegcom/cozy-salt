# Docker Installation and Repository Configuration

Docker daemon installation with auto-detection of system type and correct repository configuration.

## Location

- **State**: `srv/salt/common/docker.sls`
- **Include**: `common.init`

## Auto-Detection

Automatically selects correct Docker repository based on system:

| System          | Repo                             | Codename            |
| --------------- | -------------------------------- | ------------------- |
| Native Debian   | download.docker.com/linux/debian | {detected codename} |
| Ubuntu/WSL/Kali | download.docker.com/linux/ubuntu | noble (24.04)       |
| RHEL-based      | download.docker.com/linux/rhel   | Version-specific    |

## Detection Logic

- **WSL Detection**: Checks `/proc/version` for "Microsoft" string
- **Ubuntu Fallback**: WSL systems default to Ubuntu repo (noble codename)
- **Kali**: Treated as Ubuntu for repo compatibility
- **RHEL**: Auto-detects version and uses version-specific repo

## Pillar Override

Override auto-detection via pillar:

```yaml
docker:
  repo_path: ubuntu # or debian
  codename: focal # override detected version
```

## Installation

Installs:

- docker-ce: Docker Community Edition
- docker-ce-cli: Docker CLI
- containerd.io: Container runtime
- docker-compose-plugin: Docker Compose v2

## Usage

```bash
docker run -it ubuntu bash
docker compose up -d
```

## Notes

- Requires curl (installed via core_utils)
- Linux only (not deployed on Windows)
- Starts and enables docker.service
- May require user to be in docker group (see linux.users for group setup)
