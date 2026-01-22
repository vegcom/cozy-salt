# Pillar: Network Configuration

Network configuration for DNS, hosts file, and service entries.

## Location

- **Pillar**: `srv/pillar/common/network.sls`
- **Included in**: `top.sls` for all systems

## Configures

```yaml
network:
  dns:
    nameservers:
      - 1.1.1.1          # Cloudflare
      - 1.0.0.1          # Cloudflare backup
  hosts:
    entries:
      localhost: 127.0.0.1
      docker.local: 127.0.0.1
      k8s.local: 127.0.0.1
```

## DNS Configuration

Nameserver list for systemd-resolved:

```yaml
network:
  dns:
    nameservers:
      - 8.8.8.8          # Google DNS
      - 8.8.4.4          # Google backup
      - 1.1.1.1          # Cloudflare
```

## Hosts File Entries

Local hostname mappings:

```yaml
network:
  hosts:
    entries:
      docker.local: 127.0.0.1       # Docker Desktop
      kubernetes.local: 127.0.0.1   # K8s API
      registry.local: 127.0.0.1     # Docker Registry
```

## Platform-Specific Handling

- **Linux**: `/etc/resolv.conf` (systemd-resolved)
- **Windows**: `C:\Windows\System32\drivers\etc\hosts`
- **WSL**: Inherits Windows DNS by default

## Usage in States

States read and deploy configuration:

```sls
update_hosts:
  host.present:
    - ip: {{ entry.value }}
    - names:
      - {{ entry.key }}
```

## Customization

Override in host/class-specific pillar:

```yaml
network:
  hosts:
    entries:
      myapp.local: 192.168.1.100  # Custom host entry
```

## Notes

- Applied to all systems (cross-platform)
- DNS separate from hosts file
- WSL inherits Windows DNS settings
- Service discovery entries (Docker, K8s)
- No system outbound DNS blocking
