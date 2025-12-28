# Salt Master 3007+ (official images stopped at 3006)
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install Salt Master from Broadcom repo (3007+)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      netcat-openbsd curl gnupg gpg ca-certificates && \
    curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | \
      gpg --dearmor -o /usr/share/keyrings/salt.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/salt.gpg arch=amd64] \
      https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" > \
      /etc/apt/sources.list.d/salt.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends salt-master salt-minion salt-ssh && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Create mount points with correct ownership
# Note: /srv/salt/files is for provisioning files mounted separately
RUN mkdir -p /srv/salt/files /srv/pillar /var/cache/salt /var/log/salt && \
    chown -R salt:salt /srv /var/cache/salt /var/log/salt

# Enable master.d config drop-in directory
RUN sed -i 's/^#default_include: master.d\/\*.conf$/default_include: master.d\/*.conf/' /etc/salt/master

# Healthcheck: verify Salt Master ports are listening
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD nc -z 127.0.0.1 4505 && nc -z 127.0.0.1 4506 || exit 1

CMD ["salt-master", "-l", "info"]
