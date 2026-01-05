# Multi-stage Salt infrastructure - consolidates salt-master, salt-minion-deb, salt-minion-rpm
# Build targets: salt-master, salt-minion-deb, salt-minion-rpm

# ============================================================================
# STAGE 0: keygen
# Generate pre-shared keys for test minions at build time
# Keys are baked into images - no runtime bind mounts needed
# Salt uses standard RSA keys in PEM format
# ============================================================================
FROM ubuntu:24.04 AS keygen

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Generate RSA keys for test minions (Salt-compatible format)
WORKDIR /keys
RUN for minion in ubuntu-test rhel-test windows-test; do \
      openssl genrsa -out ${minion}.pem 4096 2>/dev/null && \
      openssl rsa -in ${minion}.pem -pubout -out ${minion}.pub 2>/dev/null; \
    done && \
    chmod 644 /keys/*.pub && \
    chmod 600 /keys/*.pem

# ============================================================================
# STAGE 1: salt-base-deb
# Common Debian/Ubuntu base with Salt repos configured
# ============================================================================
FROM ubuntu:24.04 AS salt-base-deb

ENV DEBIAN_FRONTEND=noninteractive

# Build arguments for package manager compatibility
ARG APT_MIRROR=archive.ubuntu.com
ARG APT_SECURITY_MIRROR=security.ubuntu.com
ARG DEBIAN_CODENAME=noble

# Clean up any inherited sources and set Ubuntu repos (handles Kali host environments)
RUN rm -f /etc/apt/sources.list.d/* && \
    rm -f /etc/apt/sources.list && \
    echo "deb http://${APT_MIRROR}/ubuntu/ ${DEBIAN_CODENAME} main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://${APT_MIRROR}/ubuntu/ ${DEBIAN_CODENAME}-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://${APT_SECURITY_MIRROR}/ubuntu/ ${DEBIAN_CODENAME}-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    echo "deb [arch=amd64 trusted=yes] \
      https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" > \
      /etc/apt/sources.list.d/salt.list && \
    apt-get update && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Copy entrypoint script (shared for all minion variants)
COPY scripts/docker/entrypoint-minion.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint-minion.sh

# ============================================================================
# STAGE 2: salt-master
# Salt Master 3007+ with master, minion, and SSH client
# ============================================================================
FROM salt-base-deb AS salt-master

ENV DEBIAN_FRONTEND=noninteractive

# Install Salt Master, Minion, and SSH from pre-configured repos
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      netcat-openbsd \
      salt-master salt-minion salt-ssh && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Create mount points with correct ownership
# Note: /srv/salt/files is for provisioning files mounted separately
RUN mkdir -p /srv/salt/files /srv/pillar /var/cache/salt /var/log/salt && \
    chown -R salt:salt /srv /var/cache/salt /var/log/salt /etc/salt

# Copy pre-generated public keys for test minions (pre-acceptance)
# Entrypoint copies these to /etc/salt/pki/master/minions/ on startup
COPY --from=keygen /keys/*.pub /etc/salt/pki/master/minions-preload/

# Enable master.d config drop-in directory
RUN sed -i 's/^#default_include: master.d\/\*.conf$/default_include: master.d\/*.conf/' /etc/salt/master

# Copy and set up entrypoint script (master-specific)
COPY scripts/docker/entrypoint-master.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint-master.sh

# Note: Healthcheck is defined in docker-compose.yaml (preferred for flexibility)
ENTRYPOINT ["/usr/local/bin/entrypoint-master.sh"]

# ============================================================================
# STAGE 3: salt-minion-deb
# Debian/Ubuntu minion (Ubuntu 24.04)
# ============================================================================
FROM salt-base-deb AS salt-minion-deb

ENV DEBIAN_FRONTEND=noninteractive

# Install Salt Minion from pre-configured repos
RUN apt-get update && \
    apt-get install -y --no-install-recommends salt-minion && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Pre-configure minion (master hostname will be set at runtime)
RUN mkdir -p /etc/salt/minion.d && \
    chown -R salt:salt /etc/salt && \
    chmod 755 /etc/salt /etc/salt/minion.d

# Copy pre-generated keys for test minions
# Entrypoint selects correct key based on MINION_ID
COPY --from=keygen /keys/ /etc/salt/pki/minion-preload/

ENTRYPOINT ["/usr/local/bin/entrypoint-minion.sh"]

# ============================================================================
# STAGE 4: salt-base-rpm
# Common RHEL/Rocky base with Salt repos configured
# ============================================================================
FROM rockylinux:9 AS salt-base-rpm

# Build arguments for package manager compatibility
ARG RHEL_VERSION=9

# Clean up any inherited repos (handles Kali host environments)
# but preserve system repos via subscription-manager or distro defaults
RUN rm -f /etc/yum.repos.d/kali* /etc/yum.repos.d/debian* 2>/dev/null || true && \
    dnf install -y 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release && \
    dnf clean all

# Install Salt Minion from Broadcom repo (3007+)
# Use official Salt Project repo configuration (automatically handles platform-specific paths)
RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo -o /etc/yum.repos.d/salt.repo && \
    dnf clean all && rm -rf /var/cache/dnf /tmp/*

# Copy entrypoint script
COPY scripts/docker/entrypoint-minion.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint-minion.sh

# ============================================================================
# STAGE 5: salt-minion-rpm
# RHEL/Rocky minion (Rocky Linux 9)
# ============================================================================
FROM salt-base-rpm AS salt-minion-rpm

# Install Salt Minion from pre-configured repos
RUN dnf install -y salt-minion && \
    dnf clean all && rm -rf /var/cache/dnf /tmp/*

# Pre-configure minion (master hostname will be set at runtime)
RUN mkdir -p /etc/salt/minion.d && \
    chown -R salt:salt /etc/salt && \
    chmod 755 /etc/salt /etc/salt/minion.d

# Copy pre-generated keys for test minions
# Entrypoint selects correct key based on MINION_ID
COPY --from=keygen /keys/ /etc/salt/pki/minion-preload/

ENTRYPOINT ["/usr/local/bin/entrypoint-minion.sh"]
