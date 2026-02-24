# cozy-salt TODO

## Pillar

- [x] fix pillar merge order and priority (refactor/pillar-load-order branch)
  - common → os → dist → class → users → host
    - host is LAST = final word on machine-specific overrides
    - each layer can append to or overwrite previous
  - [x] top.sls refactored with clear layer comments
  - [x] fixed host_file path check (/srv/pillar/ not /srv/salt/pillar/)
  - [x] users/*.sls now loaded (Layer 5)
  - [ ] all values audited
  - [ ] all values used where expected
  - [ ] no unexpected values remain
  - [ ] migrate complex file mgmt to better paradigms `file.replace`, jinja templates, ect

## Admin references

- [x] replace old admin references for install and defer to service user where possible, som examples below
  - example of modern `srv/salt/common/docker.sls`
  - `{% set service_user = salt['pillar.get']('managed_users', ['admin'])[0] %}`
  - `runas: admin`
  - `srv/pillar/mgmt.sls` `cozy-salt-svc`

## Docker

- [ ] use modern docker install scheme

## Seperation of duty

- [ ] Refactor config.sls
  - Presently config.sls is doing a lot of heavy lifting
  - Can be seperated by module/state

## Linux / Infra

- [ ] **cmd.run audit**: grep all states for `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern ([k3s](./srv/salt/linux/k3s.sls) pattern as reference)

## Backlog

- [x] Extract distro_aliases + package_metadata.provides to separate .map file
  - `provisioning/distro.map` or `provisioning/packages.map`
  - Use `import_yaml` to load, cleaner separation from pkg lists
  - Salt osmap pattern: <https://docs.saltproject.io/salt/user-guide/en/latest/topics/jinja.html>
- [ ] Cull verbose inline comments from .sls files, move to proper docs

## Feature

- [ ] Integrate cozy-fragments (Windows Terminal config fragments) - manual for now <<<git@github.com>:vegcom/cozy-fragments.git>>
