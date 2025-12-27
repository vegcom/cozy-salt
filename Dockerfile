# needs to use 3007, official images stopped at 3006
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install deps, Salt master (latest from repo)
RUN apt-get update && apt-get install -y netcat-openbsd curl gnupg gpg && \
  curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | \
  gpg --dearmor -o /usr/share/keyrings/salt.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/salt.gpg arch=amd64] \
  https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | \
  tee /etc/apt/sources.list.d/salt.list && \
  apt-get update && apt-get install -y salt-master salt-minion salt-ssh && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/*

# Copy Salt structure & files
COPY srv/ /srv/

# Ensure ownership (Salt pkgs create salt user/group)
RUN chown -R salt:salt /srv

# Expose ports, volumes
EXPOSE 4505 4506
VOLUME ["/srv/pillar", "/srv/salt", "/var/cache/salt", "/var/log/salt", "/etc/salt"]

# Healthcheck + entry
HEALTHCHECK CMD nc -z 127.0.0.1 4505 && nc -z 127.0.0.1 4506 || exit 1

CMD ["salt-master", "-l", "info"]
