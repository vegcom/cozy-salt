# RHEL Test Container Implementation

this doc explains what got added and why~ read if ur curious or debugging

## what got implemented

### 1. new files created

```
Dockerfile.rhel-minion           - Rocky Linux 9 container with Salt minion
tests/test-states-json.sh        - automated test runner with JSON capture
tests/parse-state-results.py     - python parser for JSON validation
tests/QUICKSTART.md              - quick reference for running tests
tests/IMPLEMENTATION.md          - this file
tests/.gitignore                 - ignore json outputs
tests/output/.gitkeep            - preserve output directory
tests/example-output.json        - sample successful test output
tests/example-failed.json        - sample failed test output
Makefile                         - convenience shortcuts
.github/workflows/test-states.yml.example - CI/CD template
```

### 2. modified files

```
docker-compose.yaml              - added salt-minion-rhel service
tests/README.md                  - expanded with state testing docs
```

## architecture

### docker compose profiles

now supports three test profiles:

```bash
--profile test-linux     # debian/ubuntu minion
--profile test-rhel      # rocky linux minion
--profile test-windows   # windows minion (existing)
```

profiles let u run specific test containers without starting all of them~

### rhel minion container

based on `rockylinux:9` because:
- free (unlike actual rhel)
- binary compatible with rhel
- maintained by the centos team
- works with dnf package manager

the dockerfile:
1. installs salt minion from broadcom repo
2. uses same entrypoint as debian minion
3. connects to salt-master on startup
4. applies highstate automatically
5. stays alive for inspection

### test workflow

```
user runs test script
  ↓
docker compose builds image
  ↓
container starts, minion connects
  ↓
entrypoint runs state.highstate
  ↓
script waits for "Highstate complete"
  ↓
captures JSON output
  ↓
parses results with jq or python
  ↓
exits with 0 (success) or 1 (failure)
```

## json output format

salt returns results like this:

```json
{
  "local": {
    "state_id_1": {
      "name": "package_name",
      "result": true,
      "comment": "what happened",
      "changes": {},
      "duration": 123.45
    },
    "state_id_2": { ... },
    "retcode": 0
  }
}
```

the parser:
- counts total states
- counts succeeded (result: true)
- counts failed (result: false)
- extracts failure details
- returns exit code for ci/cd

## testing locally

### quick test

```bash
make test-rhel
```

### verbose test

```bash
# start containers
docker compose --profile test-rhel up -d

# watch logs in real time
docker logs -f salt-minion-rhel-test

# manually capture json
docker exec salt-minion-rhel-test salt-call --local state.apply --out=json > output.json

# parse it
python3 tests/parse-state-results.py output.json

# cleanup
docker compose --profile test-rhel down
```

### debugging failures

```bash
# get shell in container
docker exec -it salt-minion-rhel-test bash

# check salt logs
cat /var/log/salt/minion

# test connectivity
salt-call --local test.ping

# check grains
salt-call --local grains.items

# manually apply state
salt-call --local state.apply
```

## ci/cd integration

### github actions

copy the example:

```bash
cp .github/workflows/test-states.yml.example .github/workflows/test-states.yml
```

features:
- matrix build (tests both distros in parallel)
- uploads json artifacts
- generates test summary in pr comments
- fails pr if states fail

### gitlab ci

add to `.gitlab-ci.yml`:

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

## how json capture works

### in entrypoint script

the entrypoint (`scripts/docker/entrypoint-minion.sh`) runs:

```bash
salt-call state.highstate --state-output=mixed
```

this applies states and shows output, but not json~

### in test script

the test script runs separately:

```bash
docker exec salt-minion-rhel-test salt-call --local state.apply --out=json
```

this re-runs the states (usually instant cache hits) and outputs json~

### why two runs?

1. first run (entrypoint): actually applies changes, human-readable output
2. second run (test script): validates results, machine-readable json

could optimize this later but it works and is simple~

## extending the tests

### adding a new distro

1. create `Dockerfile.<distro>-minion`
2. add service to `docker-compose.yaml` with `profiles: [test-<distro>]`
3. update `tests/test-states-json.sh` to support new distro
4. update docs

### adding custom validation

edit `tests/parse-state-results.py`:

```python
# example: check for specific packages
def validate_packages(data):
    required = ["vim", "git", "docker"]
    # ... check logic
```

### changing test timeout

edit `tests/test-states-json.sh`:

```bash
# line ~30
local timeout=120  # change this
```

## differences between debian and rhel testing

### package managers

- debian: `apt` / `apt-get`
- rhel: `dnf` / `yum`

states should use `pkg.installed` which handles both~

### systemd

both use systemd but:
- service names differ (e.g., `docker` vs `docker-ce`)
- some services rhel-only (e.g., `firewalld`)

### file paths

mostly the same but watch for:
- `/etc/sysconfig` (rhel) vs `/etc/default` (debian)
- selinux contexts on rhel

### python

- debian: python3 from apt
- rhel: python3.9+ from dnf

## known limitations

### no actual rhel subscription

using rocky linux means:
- no rhel-only repos
- no subscription-manager
- close enough for most testing

### container vs vm

testing in containers means:
- no real systemd pid 1 (usually)
- some kernel features unavailable
- networking simplified

good enough for salt state testing tho~

### pre-shared keys

the compose file expects keys at:
- `srv/salt/keys/rhel-test.pem`
- `srv/salt/keys/rhel-test.pub`

these are optional~ if missing, uses auto-accept (set in master config)

## performance notes

### build time

first build:
- rocky image download: ~30s
- salt install: ~45s
- total: ~90s

subsequent builds: instant (cached)

### test time

typical test run:
- container start: ~5s
- minion connect: ~10s
- state apply: ~30-120s (depends on states)
- json capture: ~2s
- total: ~60-150s

### optimizations

could speed up by:
- pre-building images in ci
- caching dnf packages
- parallel state application
- skipping redundant json capture

but honestly its fast enough~

## troubleshooting

### "salt-minion-rhel-test exited with code 1"

check logs:

```bash
docker logs salt-minion-rhel-test
```

common causes:
- salt master not healthy
- network issues
- state failures
- timeout too short

### "failed to build rhel-minion"

usually means:
- broadcom repo down
- network issues
- bad dockerfile syntax

rebuild without cache:

```bash
docker compose build --no-cache salt-minion-rhel
```

### "json file not found"

the capture failed, check:
- container still running?
- salt-call command worked?
- permissions on output dir?

### "all states show as unchanged"

second run hit cache, this is normal~

states already applied so salt says "no changes needed"

check first run logs for actual changes

## future improvements

potential enhancements:

1. **parallel testing** - run both distros at once
2. **state validation** - check specific packages installed
3. **performance metrics** - track apply duration
4. **diff comparison** - compare debian vs rhel results
5. **pre-built images** - skip build step in ci
6. **test matrix** - multiple rocky/alma versions

but honestly what we have now is pretty solid~

## comparison with existing test-linux

### similarities

- same entrypoint script
- same workflow
- same json format
- same test runner

### differences

- package manager (apt vs dnf)
- base image (ubuntu vs rocky)
- some grain values (os_family, os)

### why separate containers?

could use one "generic linux" but:
- different package managers need testing
- different systemd behaviors
- real-world has both debian and rhel
- better to catch issues early

## security considerations

### auto-accept keys

`srv/master.d/auto_accept.conf` auto-accepts minion keys

this is ONLY for testing~ production should use:
- pre-shared keys
- manual acceptance
- key fingerprint validation

### exposed ports

test containers don't expose extra ports

master ports (4505, 4506) already exposed for minions

### container privileges

no privileged mode needed

standard docker isolation is fine

### secrets in output

json output might contain:
- file paths
- package versions
- system info

don't commit output dir to git (its in .gitignore)

## maintenance

### updating salt version

edit `Dockerfile.rhel-minion`:

```dockerfile
# pin to specific version
RUN dnf install -y salt-minion-3007.1
```

or let it float (current behavior)

### updating rocky version

change base image:

```dockerfile
FROM rockylinux:9    # current
FROM rockylinux:8    # older
FROM almalinux:9     # alternative
```

### updating test dependencies

parser needs python3~ no extra deps

test runner needs:
- bash
- docker
- jq (optional)

keep it simple~

---

anyway thats the implementation~ questions? read the code ig
