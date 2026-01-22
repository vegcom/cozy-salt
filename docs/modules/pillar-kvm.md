# Pillar: KVM Virtualization Configuration

KVM/libvirt virtualization configuration for Linux testing environments.

## Location

- **Pillar**: `srv/pillar/linux/kvm.sls`
- **Included in**: Linux systems with KVM capability flag

## Purpose

Configuration for systems used as KVM hypervisors:

- Virtual machine management
- Testing environments
- Nested virtualization
- Storage pools and networks

## Configures

```yaml
kvm:
  nested: true # Enable nested virtualization
  cpu_cores: 4 # VM CPU allocation
  memory_gb: 8 # VM memory allocation
  storage_pool: /var/lib/libvirt/images
  networks:
    default:
      bridge: virbr0
      dhcp: true
```

## Requirements

Requires these capabilities/packages:

- kvm (gated by host:capabilities:kvm)
- libvirt-daemon, libvirt-clients
- qemu-kvm, qemu-system-x86

## Nested Virtualization

For testing Docker in containers:

```yaml
kvm:
  nested: true # Allows KVM inside VM
  iommu: false # Usually not needed
```

## User Groups

Group membership:

- `kvm` group: Access to /dev/kvm
- `libvirt` group: Manage VMs without sudo

## Usage

After provisioning with KVM enabled:

```bash
virsh list --all        # List VMs
virsh create vm.xml     # Create VM
qemu-img create image.qcow2 10G  # Create disk
```

## Notes

- Only applied if `host:capabilities:kvm: true`
- Requires CPU support (intel VT-x or AMD-V)
- Nested virtualization for containers
- Group membership required for non-root access
- Storage pool typically `/var/lib/libvirt/images`
