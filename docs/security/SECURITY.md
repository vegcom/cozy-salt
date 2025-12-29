# Security Considerations

## For Production

### Network Exposure

**Development:** Salt Master binds to `0.0.0.0:4505-4506` (all interfaces).

**Production:** Use firewall rules to restrict Salt ports to trusted networks only:
```bash
# Example: Only allow minions from 10.0.0.0/24
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 4505 -j ACCEPT
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 4506 -j ACCEPT
iptables -A INPUT -p tcp --dport 4505 -j DROP
iptables -A INPUT -p tcp --dport 4506 -j DROP
```

## Summary

| Component | Development | Production |
|-----------|-------------|------------|
| **Network** | All interfaces | Firewall restricted |

**Bottom line:** The default config is fine for local dev and lab. For production, use firewall restrictions to limit Salt Master access to trusted networks.

## Pillar Data Encryption

### Using GPG to Encrypt Sensitive Pillar Data

Sensitive data (passwords, API keys, tokens) should never be stored in plaintext in pillar files.

**Setup GPG encryption for pillar:**

1. Generate or import a GPG key on the Salt Master:
```bash
# Generate new key
gpg --gen-key

# Or import existing key
gpg --import < master.key.asc
```

2. Encrypt sensitive pillar data:
```bash
# Create encrypted file
echo "password: supersecret" | gpg --encrypt --recipient <key-id> --armor > /srv/pillar/secrets.sls.gpg
```

3. Configure Salt to decrypt pillar files automatically:
```yaml
# /etc/salt/master.d/pillar_encryption.conf
ext_pillar:
  - gpg: /srv/pillar

# Enable GPG-based pillar decryption
decrypt_pillar_default: gpg
```

4. Reference encrypted data in states:
```yaml
# srv/pillar/secrets.sls (encrypted with GPG)
database:
  password: !vault |
    $ANSIBLE_VAULT;...base64_encoded...
```

### Alternative: Use Salt Vault Runner

For managed secret rotation:
```bash
# Store secret
salt-run vault.write secret/data/db password=secretpass

# Retrieve in pillar
database:
  password: {{ salt['vault.read']('secret/data/db')['password'] }}
```

## Key Management

### Minion Key Lifecycle

1. **Key acceptance in production:**
   - Always use `salt-key --list` to verify pending keys before accepting
   - Never use `--auto-accept` in production
   - Implement key signing/verification procedures for critical minions

2. **Revoking compromised keys:**
```bash
# Remove minion key
salt-key -d <minion-id>

# Force minion to generate new key and re-authenticate
# On the minion:
rm -f /etc/salt/pki/minion/{minion.pem,minion.pub}
# Restart minion service and re-accept on master
```

3. **Key rotation strategy:**
   - Rotate master keys annually
   - Monitor key usage with `salt-run manage.status`
   - Keep backups of `/etc/salt/pki/master` in secure location
   - Use encrypted storage for key backups

### Master Key Protection

```bash
# Restrict master key permissions
chmod 600 /etc/salt/pki/master/master.pem
chmod 700 /etc/salt/pki/master

# Backup with encryption
tar czf - /etc/salt/pki/master | gpg --encrypt --recipient <key-id> > master-pki-backup.tar.gz.gpg
```

## Incident Response

### Security Breach Response Procedure

**If Salt Master is compromised:**

1. **Immediate containment:**
   - Isolate the master from network immediately
   - Stop the Salt daemon: `systemctl stop salt-master`
   - Preserve logs and memory dumps for forensic analysis

2. **Evidence collection:**
   - Archive `/var/log/salt/master` before any cleanup
   - Capture system state: `ps aux`, `netstat -tulpn`, mounted filesystems
   - Check `/root/.bash_history` and `/home/*/.bash_history` for unauthorized activity
   - Export minion keys: `tar czf compromised-keys-backup.tar.gz /etc/salt/pki/master`

3. **Recovery steps:**
   - Deploy fresh Salt Master on new host (rebuild from docker image)
   - Revoke all old minion keys
   - Force minion re-enrollment with new master:
     ```bash
     # On minions
     rm -f /etc/salt/pki/minion/minion.pem /etc/salt/pki/minion/minion.pub
     systemctl restart salt-minion
     ```
   - Re-accept minion keys after identity verification
   - Verify pillar and state integrity before applying states

**If minion is compromised:**

1. Remove the minion key: `salt-key -d <minion-id>`
2. Investigate what was applied via the minion's pillar/grains
3. Audit state execution history: `/var/log/salt/minion`
4. Rebuild the minion from trusted image

### Audit and Monitoring

Enable Salt audit logging:
```yaml
# /etc/salt/master.d/audit.conf
events:
  - master
  - minion
  - job_return

# Log to syslog
handlers:
  logstash:
    (): salt.log.handlers.LogstashHandler
    host: <logstash-server>
    port: 5000
    version: 1
```

Monitor for suspicious patterns:
- Multiple key acceptances/rejections in short timeframe
- State execution with `shell` or `cmd` modules on production systems
- Unexpected minion check-ins from new IPs
- Changes to security-critical states (SSH, sudo, firewall)

### Hardening Checklist

- [ ] Use firewall rules to restrict Salt ports (section above)
- [ ] Enable GPG encryption for all sensitive pillar data
- [ ] Implement key acceptance review process (never auto-accept)
- [ ] Regular key rotation schedule (annually minimum)
- [ ] Encrypted backups of master PKI directory
- [ ] Audit logging enabled and centralized
- [ ] Monitor logs for suspicious activity
- [ ] Incident response plan documented and tested
- [ ] Air-gapped backup of master configuration
