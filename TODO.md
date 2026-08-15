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
    - [ ] adopt `include:`/`extend:` ordering pattern from `windows/miniforge.sls`
      - common sls stays OS-agnostic, OS-specific sls `include:`s it then `extend:`s the
        specific state IDs to attach a `require: - cmd: os_install_state` — keeps the
        install-order coupling owned by the OS file instead of baked into common/\*
      - [ ] `common/rust.sls` currently hardcodes `require: cmd: rust_install` (windows)
            / `cmd: rust_download_and_install` (linux) via if/else — implicit contract on
            exact state ID names, should flip to `extend:` from `windows/rust.sls` +
            `linux/rust.sls` instead
      - [ ] `common/tailscale.sls` has no `require` on any install state at all —
            `tailscale_up` assumes `tailscale` binary already on PATH; fine today because
            of highstate ordering luck, fragile if run standalone. needs an install state
            to extend against (or an explicit `onlyif: which tailscale` guard + skip state)
      - [ ] audit remaining `windows/*.sls` with bare `include: common.*` for the same
            gap: `salt_minion.sls`, `sshd.sls` (already handled differently via `require_in`
        - `context`, probably fine), `tor.sls` (`.shadowsocks` include, check),
          `windhawk.sls`
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
    - [x] ~~replace with explicit slsutil.renderer + slsutil.merge in loader~~
    - [x] ~~load sources in explicit order, merge same keys manually~~
  - [ ] pillar slots
    - [slots](https://docs.saltproject.io/en/latest/topics/slots/index.html)
  - [ ] auto update salt-minion [modules/all/salt.modules.pip](https://docs.saltproject.io/en/latest/ref/modules/all/salt.modules.pip.html)
  - [ ] acl enforcement and default envs_dir to /opt/miniforge3/envs
  - [ ] install/config sysmon on windows (e.g. `sysmon -accepteula -i`)
  - [ ] incorrect naming `file.directory` accepts `makedirs` not `mkdirs` [salt.states.file](https://docs.saltproject.io/en/3006/ref/states/all/salt.states.file.html)
    - [ ] identify all instances of `file.directory` and `mkdirs` and adjust.
    - peace be with you 🙏
  - [ ] distcc not operating as expected
    - [x] ~~`~/.distcc/hosts` has to be managed~~
      - [x] per user `~/.distcc/hosts` via `srv/salt/linux/distcc.sls`
      - confirmed zeroconf/avahi discovery does not work over tailscale (no
        multicast on the mesh) — dropped `+zeroconf` from the hosts file and
        removed avahi from distcc-docker entirely, hostnames now rendered
        directly (e.g. `distcc distcc-1 distcc-2 distcc-3`)
    - [ ] `srv/salt/linux/dist/archlinux/legacy.sls` needs to haave distcc steps put into `srv/salt/linux/distcc.sls`
      - [ ] `srv/salt/linux/dist/archlinux/legacy.sls` should no longer manage distcc
      - [x] `srv/salt/linux/distcc.sls` should handle distcc mgmt (client-side; server-side already there)
      - consider leveraging `vegcom/distcc-docker` distcc container via `docker-compose.yml`
        - integrates with tailscale
        - ~~provides avahi~~ avahi removed, distccd's own zeroconf never worked over tailscale either (no broadcast domain), rely on MagicDNS hostnames instead
        - removed tagging from distcc containers, will need to likely evaluate by id instead.
          - [x] adjust distcc container evaluation in `headscale.get_distcc_hosts` — switched to `get_nodes_by_hostname_prefix`, matches `distcc`, `distcc-1`, `distcc-2`, etc. by TS_HOSTNAME pattern instead of tag
        - [ ] audit before deploy, small changes can be made for quality of life if integrated into salt echossytem
          - can be managed like `provisioning/linux/files/opt-cozy-docker/docker-proxy.yaml`

