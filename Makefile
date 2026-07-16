# cozy-salt Makefile - shortcuts for common operations

.PHONY: help test test-ubuntu test-apt test-linux test-rhel test-windows test-all test-quick \
	lint pre-commit pre-commit-install \
	up up-master down down-master restart restart-master \
	up-ubuntu-test down-ubuntu-test up-rhel-test down-rhel-test \
	up-windows-test down-windows-test \
	logs status shell debug-minion logs-minion perms \
	validate validate-states validate-states-windows state-check \
	clean clean-all \
	salt-docs salt-doc salt-doc-module salt-grains salt-grains-get \
	salt-test-ping salt-manage-status \
	salt-key-list salt-key-status salt-key-accept salt-key-delete salt-key-reject \
	salt-key-accept-test salt-key-purge-denied \
	salt-jobs-active salt-jobs-list salt-jobs-clear salt-cache-clear \
	salt-cmd salt-cmd-target \
	salt-state-highstate salt-state-highstate-test salt-state-apply salt-state-apply-test \
	salt-state-sls salt-state-sls-test salt-state-show \
	salt-call-ping salt-call-highstate salt-call-highstate-test \
	salt-call-show-top salt-call-show-highstate \
	salt-call-grains salt-call-pillar salt-call-sync salt-call-refresh-pillar salt-call-pkg-upgrades \
	mamba-create mamba-update mamba-remove mamba-activate \
	pytest pytest-ubuntu pytest-rhel pytest-windows pytest-all pytest-lint

# =========================================================================== #
# Default target
# =========================================================================== #

help:
	@echo "cozy-salt - Salt infrastructure management"
	@echo ""
	@echo "Mamba environment:"
	@echo "  mamba-create  - Create env from environment.yml"
	@echo "  mamba-update  - Update env from environment.yml"
	@echo "  mamba-remove  - Remove env"
	@echo ""
	@echo "Testing (pytest):"
	@echo "  test          - Run all pytest tests"
	@echo "  test-ubuntu   - Test Ubuntu/apt states"
	@echo "  test-rhel     - Test RHEL/dnf states"
	@echo "  test-windows  - Test Windows states"
	@echo "  test-all      - Run all distro tests"
	@echo "  test-quick    - Quick test (no docker rebuild)"
	@echo "  lint          - Run linting via pytest"
	@echo "  pre-commit    - Run pre-commit hooks on all files"
	@echo ""
	@echo "Docker/Container:"
	@echo "  up-master           - Start Salt Master"
	@echo "  down-master         - Stop all containers"
	@echo "  restart-master      - Restart master"
	@echo "  up-ubuntu-test      - Start Ubuntu test minion"
	@echo "  down-ubuntu-test    - Stop Ubuntu test minion"
	@echo "  up-rhel-test        - Start RHEL test minion"
	@echo "  down-rhel-test      - Stop RHEL test minion"
	@echo "  up-windows-test     - Start Windows test minion (requires KVM)"
	@echo "  down-windows-test   - Stop Windows test minion"
	@echo "  status              - Show container + minion status"
	@echo "  logs                - View salt-master logs (streaming)"
	@echo "  shell               - Enter salt-master container"
	@echo "  debug-minion        - Enter minion container (MINION=ubuntu)"
	@echo "  logs-minion         - Tail minion logs (MINION=ubuntu)"
	@echo ""
	@echo "Validation/Maintenance:"
	@echo "  validate                - Run pre-commit validation"
	@echo "  validate-states         - Validate Linux .sls syntax"
	@echo "  validate-states-windows - Validate Windows .sls syntax"
	@echo "  perms                   - Fix file permissions"
	@echo "  state-check             - Check state.show_top"
	@echo "  clean                   - Clean test artifacts + stop test containers"
	@echo ""
	@echo "Salt Keys:"
	@echo "  salt-key-list          - List all minion keys"
	@echo "  salt-key-accept-test   - Accept pending ubuntu-test + rhel-test keys"
	@echo "  salt-key-purge-denied  - Delete all denied keys (fix stale test keys)"
	@echo "  salt-key-accept        - Accept key by name (NAME=minion-id)"
	@echo "  salt-key-delete        - Delete key by name (NAME=minion-id)"
	@echo "  salt-key-reject        - Reject key by name (NAME=minion-id)"
	@echo ""
	@echo "Salt Connectivity:"
	@echo "  salt-test-ping         - Ping all minions"
	@echo "  salt-manage-status     - Check minion connectivity"
	@echo ""
	@echo "Salt Ad-Hoc:"
	@echo "  salt-cmd               - Run on all minions (CMD='uptime')"
	@echo "  salt-cmd-target        - Run on target (TARGET='web*' CMD='df -h')"
	@echo "  salt-grains            - Show all grains"
	@echo "  salt-grains-get        - Get grain (GRAIN=os)"
	@echo ""
	@echo "Salt State Management:"
	@echo "  salt-state-highstate      - Apply full state to all minions"
	@echo "  salt-state-highstate-test - Dry-run full state"
	@echo "  salt-state-apply          - Apply to minion (MINION=name)"
	@echo "  salt-state-sls            - Apply specific state (STATE=linux.install)"
	@echo "  salt-state-sls-test       - Dry-run specific state"
	@echo "  salt-state-show           - Preview state parsing"
	@echo ""
	@echo "Salt Jobs & Cache:"
	@echo "  salt-jobs-active       - List running jobs"
	@echo "  salt-jobs-list         - List recent jobs"
	@echo "  salt-jobs-clear        - Clear old jobs"
	@echo "  salt-cache-clear       - Clear Salt cache"
	@echo ""
	@echo "salt-call (local host):"
	@echo "  salt-call-highstate    - Apply highstate locally"
	@echo "  salt-call-pillar       - Show pillar data"
	@echo "  salt-call-grains       - Show grains"

# =========================================================================== #
# Fixtures
# =========================================================================== #

SHELL := /bin/bash

# salt-call wrapper (tries without sudo first, falls back)
SALT_CALL = sh -c 'salt-call "$$@" 2>/dev/null || exec sudo salt-call "$$@"' --

# Generic required-argument checker
require-%:
	@if [ -z "$($*)" ]; then \
		echo "Error: missing required argument '$*'"; \
		echo "Usage: make $*=<value> <target>"; \
		exit 1; \
	fi

# =========================================================================== #
# Python environment ( mamba )
# =========================================================================== #

mamba-create:
	mamba env create -f environment.yml

mamba-update:
	mamba env update --prune -f environment.yml

mamba-remove:
	mamba env remove -yn cozy-salt

mamba-activate:
	@echo "Run: mamba activate cozy-salt"

# =========================================================================== #
# Testing (pytest-based)
# =========================================================================== #

test: pytest

test-ubuntu: pytest-ubuntu

test-apt: test-ubuntu

test-linux: test-ubuntu

test-rhel: pytest-rhel

test-windows: pytest-windows

test-all: pytest-all

test-quick:
	docker compose exec -t salt-minion-ubuntu-test salt-call state.highstate --out=json

pytest:
	pytest tests/ -v --tb=short

pytest-ubuntu:
	pytest tests/ -v -m ubuntu --tb=short

pytest-rhel:
	pytest tests/ -v -m rhel --tb=short

pytest-windows:
	pytest tests/ -v -m windows --tb=short

pytest-all:
	pytest tests/ -v -m "ubuntu or rhel or windows" --tb=short

pytest-lint:
	pytest tests/test_linting.py -v

lint: pytest-lint

pre-commit-install:
	pip install pre-commit && pre-commit install

pre-commit:
	pre-commit run --all-files

# =========================================================================== #
# Docker operations
# =========================================================================== #

up-master:
	docker compose up -d salt

down-master:
	docker compose down

restart-master:
	docker compose restart salt

up-ubuntu-test:
	docker compose --profile test-ubuntu up -d salt-minion-ubuntu

down-ubuntu-test:
	docker compose --profile test-ubuntu down

up-rhel-test:
	docker compose --profile test-rhel up -d salt-minion-rhel

down-rhel-test:
	docker compose --profile test-rhel down

up-windows-test:
	docker compose --profile test-windows up -d salt-minion-windows

down-windows-test:
	docker compose --profile test-windows down

up: up-master
down: down-master
restart: restart-master

status:
	@echo "=== Container Status ===" && docker compose ps && \
	echo "" && echo "=== Minion Connectivity ===" && \
	docker compose exec -t salt salt-run manage.status 2>/dev/null || echo "(Master not running)"

logs:
	docker compose logs -f salt

clean:
	rm -f tests/output/*.json
	docker compose --profile test-ubuntu down 2>/dev/null || true
	docker compose --profile test-rhel down 2>/dev/null || true
	docker compose --profile test-windows down 2>/dev/null || true

clean-all: clean

# =========================================================================== #
# Utilities
# =========================================================================== #

validate:
	./scripts/fix-permissions.sh

perms:
	./scripts/fix-permissions.sh

shell:
	docker compose exec -it salt /bin/bash

debug-minion: require-MINION
	docker compose exec -it salt-minion-$(MINION)-test /bin/bash

logs-minion: require-MINION
	docker compose logs -f salt-minion-$(MINION)-test

state-check:
	docker compose exec -t salt salt-call state.show_top 2>/dev/null || echo "Error: Check state syntax in srv/salt/"

validate-states:
	@echo "=== Validating Salt state files (Linux) ==="
	@echo "(Skipping srv/salt/windows/* - requires Windows Salt)"
	@failed=0; \
	for sls in $$(find srv/salt -name "*.sls" -type f ! -path "*/windows/*"); do \
		salt_path="salt://$$(echo $$sls | sed 's|srv/salt/||')"; \
		if ! docker compose exec -T salt salt-call --local --file-root=/srv/salt --file-root=/provisioning slsutil.renderer "$$salt_path" >/dev/null 2>&1; then \
			echo "FAIL: $$sls"; \
			docker compose exec -T salt salt-call --local --file-root=/srv/salt --file-root=/provisioning slsutil.renderer "$$salt_path" 2>&1 | tail -5; \
			failed=$$((failed + 1)); \
		else \
			echo "  OK: $$sls"; \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo ""; echo "=== $$failed file(s) failed validation ==="; exit 1; \
	else \
		echo ""; echo "=== All Linux state files valid ==="; \
	fi

validate-states-windows:
	@echo "=== Validating Windows state files ==="
	@failed=0; \
	for sls in $$(find srv/salt/windows -name "*.sls" -type f); do \
		salt_path="salt://$$(echo $$sls | sed 's|srv/salt/||')"; \
		if ! salt-call --local slsutil.renderer "$$salt_path" >/dev/null 2>&1; then \
			echo "FAIL: $$sls"; \
			salt-call --local slsutil.renderer "$$salt_path" 2>&1 | tail -5; \
			failed=$$((failed + 1)); \
		else \
			echo "  OK: $$sls"; \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo ""; echo "=== $$failed file(s) failed validation ==="; exit 1; \
	else \
		echo ""; echo "=== All Windows state files valid ==="; \
	fi

# =========================================================================== #
# Salt-Master helpers
# =========================================================================== #

salt-doc:
	docker compose exec -t salt salt '*' sys.doc

salt-doc-module: require-MODULE
	docker compose exec -t salt salt '*' sys.doc $(MODULE)

salt-cmd: require-CMD
	docker compose exec -t salt salt '*' cmd.run '$(CMD)'

salt-cmd-target: require-TARGET require-CMD
	docker compose exec -t salt salt '$(TARGET)' cmd.run '$(CMD)'

salt-grains:
	docker compose exec -t salt salt '*' grains.items

salt-grains-get: require-GRAIN
	docker compose exec -t salt salt '*' grains.item $(GRAIN)

salt-state-sls: require-STATE
	docker compose exec -t salt salt '*' state.sls $(STATE)

salt-state-sls-test: require-STATE
	docker compose exec -t salt salt '*' state.sls $(STATE) test=true

salt-state-show: require-STATE
	docker compose exec -t salt salt '*' state.show_sls $(STATE)

salt-cache-clear:
	docker compose exec -t salt salt '*' saltutil.clear_cache

salt-key-list:
	docker compose exec -t salt salt-key -L

salt-key-status: salt-key-list

salt-key-accept: require-NAME
	docker compose exec -t salt salt-key -a "$(NAME)" -y || true

salt-key-delete: require-NAME
	docker compose exec -t salt salt-key -d "$(NAME)" -y || true

salt-key-reject: require-NAME
	docker compose exec -t salt salt-key -r "$(NAME)" -y || true

# Accept pre-baked test keys (fallback if entrypoint didn't auto-accept)
salt-key-accept-test:
	docker compose exec -t salt salt-key -a ubuntu-test -y 2>/dev/null || true
	docker compose exec -t salt salt-key -a rhel-test -y 2>/dev/null || true
	docker compose exec -t salt salt-key -L

# Purge all denied keys (fixes stale denied state after container rebuild)
salt-key-purge-denied:
	docker compose exec -t salt salt-key -D -y 2>/dev/null || true
	docker compose exec -t salt salt-key -L

salt-manage-status:
	docker compose exec -t salt salt-run manage.status

salt-jobs-active:
	docker compose exec -t salt salt-run jobs.active

salt-jobs-list:
	docker compose exec -t salt salt-run jobs.list_jobs

salt-jobs-clear:
	docker compose exec -t salt salt-run jobs.clear_old_jobs 2>/dev/null || echo "No old jobs to clear"

salt-test-ping:
	docker compose exec -t salt salt '*' test.ping

salt-state-highstate:
	docker compose exec -t salt salt '*' state.highstate

salt-state-highstate-test:
	docker compose exec -t salt salt '*' state.highstate test=true

salt-state-apply: require-MINION
	docker compose exec -t salt salt '$(MINION)' state.highstate

salt-state-apply-test: require-MINION
	docker compose exec -t salt salt '$(MINION)' state.highstate test=true

# =========================================================================== #
# salt-call: local host
# =========================================================================== #

salt-call-ping:
	$(SALT_CALL) test.ping

salt-call-highstate:
	$(SALT_CALL) state.highstate --state-output=terse -l warning

salt-call-highstate-test:
	$(SALT_CALL) state.highstate test=True --state-output=terse -l warning

salt-call-show-top:
	$(SALT_CALL) state.show_top

salt-call-show-highstate:
	$(SALT_CALL) state.show_highstate

salt-call-grains:
	$(SALT_CALL) grains.items

salt-call-pillar:
	$(SALT_CALL) pillar.items

salt-call-sync:
	$(SALT_CALL) saltutil.sync_all

salt-call-refresh-pillar:
	$(SALT_CALL) saltutil.refresh_pillar

salt-call-pkg-upgrades:
	$(SALT_CALL) pkg.list_upgrades
