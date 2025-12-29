# Quick Start - Testing Salt States

this is how u actually test ur states without breaking production~ follow along bestie

## tl;dr

```bash
# test everything at once
./tests/test-states-json.sh all

# or test specific distros
./tests/test-states-json.sh linux   # debian/ubuntu
./tests/test-states-json.sh rhel    # rocky/alma/rhel
```

## what it does

1. spins up a fresh container (debian or rocky linux)
2. installs salt minion
3. connects to salt master
4. applies all states from top.sls
5. captures results as JSON
6. tells u if anything broke

## manual mode (for when ur debugging at 3am)

```bash
# start containers
docker compose --profile test-rhel up -d

# watch it work
docker logs -f salt-minion-rhel-test

# poke around inside
docker exec -it salt-minion-rhel-test bash

# check what happened
docker exec salt-minion-rhel-test salt-call --local state.apply --out=json

# clean up
docker compose --profile test-rhel down
```

## reading the output

### script output (colorized summary)

```bash
./tests/test-states-json.sh rhel

# shows:
# - green if everything worked
# - red if states failed
# - yellow for warnings
# - saves full JSON to tests/output/
```

### json files (raw data)

```bash
# look at recent test
ls -lt tests/output/

# parse it urself
python3 tests/parse-state-results.py tests/output/rhel_20231215_120000.json

# or use jq if ur fancy
jq '.local | keys' tests/output/rhel_latest.json
```

## ci/cd integration

### github actions

```bash
# copy the example
cp .github/workflows/test-states.yml.example .github/workflows/test-states.yml

# commit and push
git add .github/workflows/test-states.yml
git commit -m "add state testing"
git push
```

now every PR gets tested automatically~ ur welcome

### gitlab ci

add this to `.gitlab-ci.yml`:

```yaml
test:rhel:
  stage: test
  services:
    - docker:dind
  script:
    - ./tests/test-states-json.sh rhel
  artifacts:
    when: always
    paths:
      - tests/output/*.json
```

## common issues

### "container exited prematurely"

```bash
# check what died
docker logs salt-minion-rhel-test

# usually means:
# - salt master isn't running
# - network is borked
# - minion keys got rejected
```

### "timeout waiting for state application"

```bash
# states are slow or stuck
# check minion logs
docker exec salt-minion-rhel-test cat /var/log/salt/minion

# or just wait longer (edit test-states-json.sh)
```

### "jq not found"

```bash
# tests still work, just less pretty
# install it if u want colors:
apt install jq    # debian
dnf install jq    # rhel
brew install jq   # mac
```

## pro tips

1. **run tests before pushing** - save urself the embarrassment
2. **check both distros** - debian and rhel r different enough to matter
3. **save the json** - helps when debugging weird failures
4. **read the logs** - container logs have the actual error messages

## what gets tested

whatever ur top.sls applies:
- `/var/syncthing/Git share/cozy-salt/srv/salt/top.sls`

for rhel specifically:
- `os_family:RedHat` grain matches
- dnf package installs
- systemd services
- file deployments

## example workflow

```bash
# 1. make changes to states
vim srv/salt/linux/base.sls

# 2. test locally
./tests/test-states-json.sh linux

# 3. if it works, test rhel too
./tests/test-states-json.sh rhel

# 4. commit and push
git add srv/salt/linux/base.sls
git commit -m "update base state"
git push

# 5. watch CI run the same tests
# github.com/yourrepo/actions
```

## need help?

check the full docs: [README.md](README.md)

or just... read the error message ig~ it usually tells u what's wrong

---

anyway good luck with ur infrastructure or whatever
