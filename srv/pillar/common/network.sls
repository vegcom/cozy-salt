# Network Configuration
# DNS, hosts, and network-level settings for all platforms

network:
  # DNS configuration (for bare metal/VMs, skipped in containers)
  dns:
    search_domain: local
    nameservers:
      - 10.0.0.1    # Local router/DNS
      - 1.1.1.1     # Cloudflare primary
      - 1.0.0.1     # Cloudflare secondary

  # Hosts file entries for network services (replaces hardcoded entries)
  hosts:
    unifi: 10.0.0.1              # UniFi controller
    guava: 10.0.0.2              # Primary host
    ipa.guava.local: 10.0.0.110  # IPA identity server
    romm.local: 10.0.0.3         # ROMM service
