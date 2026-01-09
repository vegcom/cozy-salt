# Makefile Salt Target Review

> Author: @agent-egirl-ops  
> Date: 2025-12-30  
> Status: Proposal

reviewed the Makefile, cross-checked against Salt docs. there are... issues. but fixable ones~

## Sources Consulted

- [SaltStack Cheatsheet](https://automatewithsalt.github.io/saltstack-cheatsheet/)
- [Salt Remote Execution Docs](https://docs.saltproject.io/en/latest/topics/execution/remote_execution.html)
- [Salt CLI Reference](https://docs.huihoo.com/saltstack/ref/cli/index.html)
- [DeepWiki saltstack/salt](https://deepwiki.com/saltstack/salt)

---

## Current State Analysis

### Naming Inconsistencies

| Target | Issue |
|--------|-------|
| `salt-clear_cache` | Uses underscore, everything else uses dashes |
| `salt-key-list` vs `salt-key-status` | Both run `salt-key -L`, redundant |
| `salt-key-cleanup-test` vs `clean-keys` | Duplicate functionality |
| `salt-test-ping` | Verb placement inconsistent with `salt-state-highstate` |
| `test-apt`, `test-linux` | Both alias to `test-ubuntu`, confusing |

### Bugs Found

1. **Line 209**: Typo `documentaiton` should be `documentation`
2. **Line 254**: Trailing `d` after echo: `echo "No old jobs to clear"d`

### Missing Common Operations

Based on Salt documentation, these frequently-used commands have no Makefile targets:

| Command | Purpose | Priority |
|---------|---------|----------|
| `salt '*' sys.doc` | Module documentation lookup | HIGH |
| `salt '*' cmd.run` | Ad-hoc command execution | HIGH |
| `salt '*' grains.items` | View all grains | HIGH |
| `salt '*' state.sls STATE` | Apply specific state file | HIGH |
| `salt-key -A` | Accept ALL pending keys | MEDIUM |
| `salt-run manage.up` | List responsive minions | MEDIUM |
| `salt-run manage.down` | List unresponsive minions | MEDIUM |
| `salt '*' test.version` | Salt version on minions | MEDIUM |
| `salt '*' status.uptime` | Minion uptime | LOW |
| `salt '*' network.ip_addrs` | IP address listing | LOW |
| `salt '*' service.*` | Service management | LOW |

---

## Proposed Naming Convention

Pattern: `[context]-[noun]-[verb]` or `[context]-[verb]`

### Prefix Meanings

| Prefix | Runs On | Targets | Example |
|--------|---------|---------|---------|
| `salt-` | Master | Minions via `salt '*'` | `salt-ping` |
| `salt-run-` | Master | Master only via `salt-run` | `salt-run-status` |
| `salt-key-` | Master | Key management via `salt-key` | `salt-key-list` |
| `salt-call-` | Local | Local minion via `salt-call` | `salt-call-ping` |

### Verb Consistency

| Verb | Meaning | Example |
|------|---------|---------|
| `list` | Display collection | `salt-key-list` |
| `show` | Display single item | `salt-state-show` |
| `apply` | Execute state | `salt-state-apply` |
| `run` | Execute command | `salt-cmd-run` |
| `test` | Dry-run mode | `salt-highstate-test` |
| `accept`/`reject`/`delete` | Key actions | `salt-key-accept` |
| `clear`/`refresh` | Cache operations | `salt-cache-clear` |

---

## Proposed Changes

### Renames (Breaking)

| Current | Proposed | Rationale |
|---------|----------|-----------|
| `salt-clear_cache` | `salt-cache-clear` | Consistent dash naming |
| `salt-test-ping` | `salt-ping` | Simpler, `test.ping` implied |
| `salt-manage-status` | `salt-run-status` | Clearer that it's a runner |
| `salt-state-highstate` | `salt-highstate` | Shorter, common operation |
| `salt-state-highstate-test` | `salt-highstate-test` | Match above |

### Removals (Keep as aliases)

| Target | Reason |
|--------|--------|
| `salt-key-status` | Duplicate of `salt-key-list` |
| `test-apt` | Alias for `test-ubuntu`, document instead |
| `test-linux` | Alias for `test-ubuntu`, document instead |

### New Targets

#### HIGH Priority

```makefile
# Discovery & Documentation
salt-doc:
	docker compose exec -t salt-master salt '*' sys.doc

salt-doc-module: require-MODULE
	docker compose exec -t salt-master salt '*' sys.doc $(MODULE)

# Ad-hoc Command Execution  
salt-cmd: require-CMD
	docker compose exec -t salt-master salt '*' cmd.run '$(CMD)'

salt-cmd-target: require-TARGET require-CMD
	docker compose exec -t salt-master salt '$(TARGET)' cmd.run '$(CMD)'

# Grains (System Info)
salt-grains:
	docker compose exec -t salt-master salt '*' grains.items

salt-grains-get: require-GRAIN
	docker compose exec -t salt-master salt '*' grains.item $(GRAIN)

# State Management
salt-state-sls: require-STATE
	docker compose exec -t salt-master salt '*' state.sls $(STATE)

salt-state-sls-test: require-STATE
	docker compose exec -t salt-master salt '*' state.sls $(STATE) test=true

salt-state-show: require-STATE
	docker compose exec -t salt-master salt '*' state.show_sls $(STATE)
```

#### MEDIUM Priority

```makefile
# Key Management
salt-key-accept-all:
	docker compose exec -t salt-master salt-key -A -y

salt-key-reject-all:
	docker compose exec -t salt-master salt-key -R -y

# Runner Status
salt-run-up:
	docker compose exec -t salt-master salt-run manage.up

salt-run-down:
	docker compose exec -t salt-master salt-run manage.down

# Version & Uptime
salt-version:
	docker compose exec -t salt-master salt '*' test.version

salt-uptime:
	docker compose exec -t salt-master salt '*' status.uptime
```

#### LOW Priority (Nice to Have)

```makefile
# Network Diagnostics
salt-network-ip:
	docker compose exec -t salt-master salt '*' network.ip_addrs

salt-network-ping: require-HOST
	docker compose exec -t salt-master salt '*' network.ping $(HOST)

# Service Management
salt-service-status: require-SERVICE
	docker compose exec -t salt-master salt '*' service.status $(SERVICE)

salt-service-start: require-SERVICE
	docker compose exec -t salt-master salt '*' service.start $(SERVICE)

salt-service-stop: require-SERVICE
	docker compose exec -t salt-master salt '*' service.stop $(SERVICE)

salt-service-restart: require-SERVICE
	docker compose exec -t salt-master salt '*' service.restart $(SERVICE)

# Package Management
salt-pkg-install: require-PKG
	docker compose exec -t salt-master salt '*' pkg.install $(PKG)
```

---

## Proposed Help Output Reorganization

```
Salt Discovery:
  salt-doc              - Show all module documentation
  salt-doc-module       - Show docs for MODULE (usage: make salt-doc-module MODULE=pkg)
  salt-version          - Show Salt version on all minions
  salt-grains           - Show all grains on all minions
  salt-grains-get       - Get specific grain (usage: make salt-grains-get GRAIN=os)
  salt-pillar           - Show pillar data (existing salt-call-pillar)

Salt Connectivity:
  salt-ping             - Ping all minions
  salt-run-status       - Show minion status (up/down)
  salt-run-up           - List responsive minions
  salt-run-down         - List unresponsive minions

Salt Key Management:
  salt-key-list         - List all minion keys
  salt-key-accept       - Accept key (usage: make salt-key-accept NAME=minion)
  salt-key-accept-all   - Accept ALL pending keys
  salt-key-reject       - Reject key (usage: make salt-key-reject NAME=minion)
  salt-key-delete       - Delete key (usage: make salt-key-delete NAME=minion)

Salt State Management:
  salt-highstate        - Apply full state to all minions
  salt-highstate-test   - Dry-run full state (test mode)
  salt-state-apply      - Apply to specific minion (usage: make salt-state-apply MINION=name)
  salt-state-sls        - Apply specific state (usage: make salt-state-sls STATE=linux.install)
  salt-state-show       - Preview state parsing (usage: make salt-state-show STATE=linux)

Salt Ad-Hoc Execution:
  salt-cmd              - Run command on all minions (usage: make salt-cmd CMD='uptime')
  salt-cmd-target       - Run on specific target (usage: make salt-cmd-target TARGET='web*' CMD='df -h')

Salt Jobs:
  salt-jobs-active      - List running jobs
  salt-jobs-list        - List recent jobs
  salt-jobs-clear       - Clear old jobs

Salt Cache:
  salt-cache-clear      - Clear Salt cache on all minions
```

---

## Implementation Notes

### Backward Compatibility

Keep old target names as aliases for one release cycle:

```makefile
# DEPRECATED: Use salt-ping instead
salt-test-ping: salt-ping

# DEPRECATED: Use salt-cache-clear instead  
salt-clear_cache: salt-cache-clear
```

### Parameterized Targets

The existing `require-%` pattern is good. New targets should follow it:

```makefile
require-%:
	@if [ -z "$($*)" ]; then \
		echo "Error: missing required argument '$*'"; \
		echo "Usage: make $*=<value> <target>"; \
		exit 1; \
	fi
```

### Bug Fixes Required

1. Fix typo in `salt-help` (line 209)
2. Remove trailing `d` from `salt-jobs-clear` (line 254)

---

## Summary

| Category | Count |
|----------|-------|
| Renames | 5 |
| Removals | 3 |
| New HIGH priority | 8 |
| New MEDIUM priority | 5 |
| New LOW priority | 7 |
| Bug fixes | 2 |

The biggest wins are `salt-doc`, `salt-cmd`, and `salt-grains` - these are the commands I actually use the most when debugging Salt stuff, and they're just... not there rn.

---

anyway thats the review. lmk if u want me to implement any of this~
