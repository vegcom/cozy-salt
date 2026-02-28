# cozy-salt TODO

## Tests

- [x] minion container tests are not automated, this needs to be put back in place
  - [x] containers must be evaluated (ubuntu + rhel passing CI as of 87c95e9)

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

- [ ] Cull verbose inline comments from .sls files, move to proper docs

## Git Hooks

- [ ] Convert `provisioning/common/dotfiles/.git_template/hooks/commit-msg` to Python for Windows compatibility

## Feature

- [ ] Wire up template `srv/salt/_templates/alacritty.jinja` path depends on OS
