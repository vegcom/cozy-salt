# cozy-salt TODO


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


## Feature

- [ ] Wire up template `srv/salt/_templates/alacritty.jinja` path depends on OS
