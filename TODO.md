# cozy-salt TODO

## CI/CD

- [ ] enable and debug `.github/workflows/test-states.yml`

## Tests

- [ ] minion container tests are not automated, this needs to be put back in place
  - [ ] containers must be evaluated
  - each changed state could also go through pre-commit for evaluation this way

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

- [x] use modern docker install scheme
- [ ] Gate `container` capability in `srv/pillar/linux/init.sls` with `pillar_gate: docker_enabled` to skip docker install on non-docker hosts

## Seperation of duty

- [ ] Refactor config.sls
  - Presently config.sls is doing a lot of heavy lifting
  - Can be seperated by module/state

## Infra

- [ ] **cmd.run audit**: grep all states for `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern ([k3s](./srv/salt/linux/k3s.sls) pattern as reference)
  - [ ] windows
    - [ ] Invoke-WebRequest
    - [ ] miniforge
    - [ ] nvm
    - [ ] windhawk
    - [ ] ... find more ...
  - [ ] linux
    - [ ] curl & wget
    - [ ] miniforge
    - [ ] nvm
    - [ ] rust
    - [ ] ... find more ...

## Backlog

- [x] Extract distro_aliases + package_metadata.provides to separate .map file
  - `provisioning/distro.map` or `provisioning/packages.map`
  - Use `import_yaml` to load, cleaner separation from pkg lists
  - Salt osmap pattern: <https://docs.saltproject.io/salt/user-guide/en/latest/topics/jinja.html>
- [ ] Cull verbose inline comments from .sls files, move to proper docs

## Git Hooks

- [ ] Convert `provisioning/common/dotfiles/.git_template/hooks/commit-msg` to Python for Windows compatibility

## Feature

- [x] Integrate cozy-fragments (Windows Terminal config fragments) - wired via srv/salt/windows/wt.sls
- [ ] Wire up template `srv/salt/_templates/alacritty.jinja` path depends on OS
