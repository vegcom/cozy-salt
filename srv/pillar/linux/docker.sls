#!jinja|yaml

docker_compose:

  distcc:
    path: /opt/cozy/docker/
    files: [/opt/cozy/docker/distcc.yaml]
    env:
      TS_AUTHKEY: __salt_pillar_headscale:auth-key
      TS_SERVER: __salt_pillar_headscale:login-server
    services:
      distcc-docker:
        tags: ['salt-managed', 'distcc']

  proxy:
    path: /opt/cozy/docker/
    files: [/opt/cozy/docker/docker-proxy.yaml]
    services:
      distcc-docker:
        tags: ['salt-managed', 'docker-proxy', 'dockerd']
