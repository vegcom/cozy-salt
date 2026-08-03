# cozy-salt TODO

> [!NOTE]
> Want to join in? Check the
> [vegcom/cozy-salt/develop](https://github.com/vegcom/cozy-salt/tree/develop)
> branch

<!-- a_cute_template:
- [ ] namespace/repo
  - [ ] feat: description
    - [ ] elaboration on topics
- [ ] orgspace/repo
  - [ ] refactor: description
    - [ ] elaboration on topics
-->

## Infra/Future

- [ ] [vegcom/cozy-salt](https://github.com/vegcom/cozy-salt/tree/develop)
  - [ ] refactor: modernize_formula
    - [ ] `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern `srv/salt/linux/k3s.sls` pattern as reference
      - [x] windows
        - [x] nvm
        - [x] miniforge
        - [x] qmk_msys
        - [x] rust
        - [x] salt
      - [ ] linux
  - [x] udev rules
    - [Irongeek writeup on udev lockdown](https://www.irongeek.com/i.php?page=security/plug-and-prey-malicious-usb-devices#3.2_Locking_down_Linux_using_UDEV)
    - [x] base
    - [x] ~~harden~~ no longer hardening with saltstack
    - [x] reporting
  - [ ] iptables rules
    - [ ] base
    - [ ] harden
    - [ ] reporting
  - [x] pillar merge strategy: recurse broken across matchers in salt 3008.0rc2
    - [issues/68785](https://github.com/saltstack/salt/issues/68785)
    - [issues/59443](https://github.com/saltstack/salt/issues/59443)
    - [x] ~replace with explicit slsutil.renderer + slsutil.merge in loader~
    - [x] ~load sources in explicit order, merge same keys manually~
  - [ ] pillar slots
    - [slots](https://docs.saltproject.io/en/latest/topics/slots/index.html)
  - [ ] auto update salt-minion [modules/all/salt.modules.pip](https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.pip.html)
