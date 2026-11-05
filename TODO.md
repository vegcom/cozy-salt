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
  - [ ] chore:windows-sysmon
    - install/config sysmon on windows (e.g. `sysmon -accepteula -i`)
  - [ ] refactor:windows-nvm
    - presently the installer leveraged in windows/nvm.sls no longer supports a custom path
    - this should be addressed in part by having windows common.nvm branch facilitate per user node installs
