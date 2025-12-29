# CLAUDE.md - cozy-salt AI Guide

SaltStack IaC for Windows/Linux provisioning. Master in Docker. production ready.

## 3 rules. don't break them.

1. **packages go in `provisioning/packages.sls`** - states import, never hardcode
2. **files live in `provisioning/`** - states orchestrate, files deploy
3. **before moving ANYTHING, grep for references** - silent failures suck worse than broken code

## grep before u ship

moving/renaming/deleting? search everywhere first:

```bash
grep -Hnr "old_path" srv/salt/ srv/pillar/ provisioning/ scripts/ .github/ tests/ scripts/ docs/ *.md Makefile TODO.md SECURITY.md README.md
```

check: `file.managed` sources, `cmd.run` paths, `salt://` references, `top.sls` state names.

## when it breaks

- state not found? check `top.sls` and filename match
- file not found? check `provisioning/` is mounted and readable
- minion hanging? master needs 15s after restart
- permissions? `chmod -R 755 provisioning/` (salt runs as uid 999)

see **CONTRIBUTING.md** for details and setup.

## how we actually work here

- **check DeepWiki + Omnisearch FIRST** - before suggesting changes, know what exists
- **Desktop Commander for file edits** - not Edit/Write tools. use `edit_block` or `write_file` through it
- **Desktop Commander for tests** - `start_process`, run `tests/run.sh`, actually verify shit works
- **Memory + Sequential Thinking** - use these often. document decisions, track context, think out loud
- **grep before u move anything** - see rule #3. seriously. do it.