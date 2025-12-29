# Security Documentation

Security hardening guides for cozy-salt production deployments.

## Security Guide

- **[Security Hardening](SECURITY.md)** - Complete guide covering:
  - Network exposure and firewall rules
  - Pillar data encryption with GPG
  - Key management and rotation
  - Incident response procedures
  - Audit and monitoring setup
  - Hardening checklist

## Key Topics

### Network Security
- Firewall configuration for Salt Master ports (4505, 4506)
- Network isolation best practices

### Data Encryption
- GPG-based pillar data encryption
- Salt Vault integration for secret management
- Encrypted key backups

### Key Management
- Minion key lifecycle
- Master key protection
- Key rotation strategies
- Key recovery procedures

### Incident Response
- Breach containment procedures
- Evidence collection
- Master/minion recovery steps
- Audit logging setup

### Hardening Checklist
Complete checklist for production deployments including:
- Firewall rules
- Encryption setup
- Key management
- Audit logging
- Monitoring configuration

## Important Notes

- Default configurations are suitable for **local development only**
- Always review security hardening before deploying to production
- Follow the hardening checklist for production deployments
- Enable audit logging and monitoring in production

## Next Steps

- Read [Security Hardening Guide](SECURITY.md) for detailed instructions
- See [Deployment Guide](../deployment/) for operational guidance
- See [Contributing Guide](../development/CONTRIBUTING.md) for development security notes
