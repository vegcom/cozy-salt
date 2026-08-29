#!jinja|yaml

docker_compose:

  distcc-docker:
    path: /opt/cozy/docker/
    files: [/opt/cozy/docker/distcc.yaml]
    services:
      distcc-docker:
        tags: ['salt-managed', 'distcc']

  docker-proxy:
    path: /opt/cozy/docker/
    files: [/opt/cozy/docker/docker-proxy.yaml]
    services:
      distcc-docker:
        tags: ['salt-managed', 'docker-proxy', 'dockerd']
