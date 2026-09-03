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
  - [ ] acl enforcement and default envs_dir to /opt/miniforge3/envs
  - [ ] install/config sysmon on windows (e.g. `sysmon -accepteula -i`)
  - [ ] incorrect naming `file.directory` accepts `makedirs` not `mkdirs` [salt.states.file](https://docs.saltproject.io/en/3006/ref/states/all/salt.states.file.html)
    - [ ] identify all instances of `file.directory` and `mkdirs` and adjust.
    - peace be with you 🙏
  - DistCC
    - [ ] have salt deploy distcc containers per avaial host.
  - [ ] windows/winget move to github.com/June-Cozy/ backing to prevent having to eval making list
