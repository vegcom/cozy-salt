# cozy-salt TODO

<!-- a_cute_template:
- [ ] namespace/repo
  - [ ] feat: description
    - [ ] elaboration on topics
- [ ] orgspace/repo
  - [ ] refactor: description
    - [ ] elaboration on topics
-->

## Infra/Future

- [ ] vegcom/cozy-salt
  - [ ] refactor: modernize_formula
    - [ ] `cmd.run.*(wget|curl)` and migrate to `file.managed` + `cmd.run` pattern `srv/salt/linux/k3s.sls` pattern as reference
  - [x] salt gate pillar secrets loads
    - [x] /home/vegcom/git/cozy-salt/srv/pillar/secrets/init.sls
  - [x] gw get tcpdups
    - [x] to
    - [x] from
  - [x] udev rules
    - [Irongeek writeup on udev lockdown](https://www.irongeek.com/i.php?page=security/plug-and-prey-malicious-usb-devices#3.2_Locking_down_Linux_using_UDEV)
  - [ ] iptables rules
  - [x] docker `daemon.json`
    - [x] pillar - config_paths:docker
    - [x] state - srv/salt/linux/docker.sls
  - [x] headscale
    - [x] /home/vegcom/git/cozy-headscale/make/headscale.mk -- refactor and make warmer
    - [x] /home/vegcom/git/cozy-salt/srv/pillar/secrets/headscale.sls -- post wipe
  - [x] k3s/docker class pillar not merging via recurse strategy
    - [x] use slsutil.renderer + slsutil.merge in state instead of pillar merge
    - [ ] same pattern as docker daemon.json jq merge approach
  - [x] pillar unified loader
    - [x] single SLS to replace dynamic top.sls sections (secrets, classes, host, hardware)
    - [x] one file to edit when adding new dynamic pillar sources
  - [x] pillar merge strategy: recurse broken across matchers in salt 3008.0rc2
    - [issues/68785](https://github.com/saltstack/salt/issues/68785)
    - [issues/59443](https://github.com/saltstack/salt/issues/59443)
    - [ ] ~replace with explicit slsutil.renderer + slsutil.merge in loader~
    - [ ] ~load sources in explicit order, merge same keys manually~
  - [ ] pillar slots
    - [slots](https://docs.saltproject.io/en/latest/topics/slots/index.html)
