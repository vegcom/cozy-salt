# cozy-salt Makefile - shortcuts for common operations

.PHONY: help test test-ubuntu test-apt test-linux test-rhel test-windows test-all test-quick lint lint-shell lint-ps clean clean-keys clean-all up up-master down down-master restart restart-master up-ubuntu-test down-ubuntu-test up-rhel-test down-rhel-test logs status validate validate-states validate-states-windows perms shell state-check debug-minion logs-minion salt-help salt-key-list salt-key-status salt-key-cleanup-test salt-key-accept salt-key-delete salt-key-reject salt-key-accept-test salt-manage-status salt-jobs-active salt-jobs-list salt-jobs-clear salt-test-ping salt-state-highstate salt-state-highstate-test pytest pytest-ubuntu pytest-rhel pytest-windows pytest-all pytest-lint salt-doc salt-cmd salt-grains salt-state-sls salt-cache-clear salt-clear_cache mamba-create mamba-update mamba-remove mamba-activate

# =========================================================================== #
# Default target
# =========================================================================== #

help:
	@echo "cozy-salt - Salt infrastructure management"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "Mamba environment:"
	@echo "  mamba-create: Create the environment from environment.yml"
	@echo "  mamba-update: Update the environment from environment.yml"
	@echo "  mamba-remove: Remove the environment"
	@echo "  mamba-activate: Prints activation instructions"
	@echo ""
	@echo "Testing (pytest):"
	@echo "  test          - Run all pytest tests"
	@echo "  test-ubuntu   - Test Ubuntu/apt states (pytest -m ubuntu)"
	@echo "  test-rhel     - Test RHEL/dnf states (pytest -m rhel)"
	@echo "  test-windows  - Test Windows states (pytest -m windows)"
	@echo "  test-all      - Run all distro tests"
	@echo "  test-quick    - Quick test without docker rebuild"
	@echo "  lint          - Run linting via pytest"
	@echo ""
	@echo "pytest (direct):"
	@echo "  pytest        - Run all tests with verbose output"
	@echo "  pytest-ubuntu - Ubuntu tests only"
	@echo "  pytest-rhel   - RHEL tests only"
	@echo "  pytest-windows- Windows tests only"
	@echo "  pytest-lint   - Linting tests only"
	@echo ""
	@echo "Docker/Container:"
	@echo "  up-master           - Start Salt Master"
	@echo "  down-master         - Stop all containers"
	@echo "  restart-master      - Restart master"
	@echo "  up-ubuntu-test      - Start Ubuntu test minion"
	@echo "  down-ubuntu-test    - Stop Ubuntu test minion"
	@echo "  up-rhel-test        - Start RHEL test minion"
	@echo "  down-rhel-test      - Stop RHEL test minion"
	@echo "  up-windows-test     - Start Windows test minion (Dockur, requires KVM)"
	@echo "  down-windows-test   - Stop Windows test minion"
	@echo "  setup-windows-keys  - Generate Windows test minion keys"
	@echo "  status              - Show container + minion status"
	@echo "  logs                - View salt-master logs (streaming)"
	@echo "  shell               - Enter salt-master container"
	@echo "  debug-minion        - Enter minion container (MINION=ubuntu)"
	@echo "  logs-minion         - Tail minion logs (MINION=ubuntu)"
	@echo ""
	@echo "Validation/Maintenance:"
	@echo "  validate                - Run pre-commit validation (permissions + optional linting)"
	@echo "  validate-states         - Validate Linux .sls files (YAML/Jinja syntax)"
	@echo "  validate-states-windows - Validate Windows .sls files (run on Windows)"
	@echo "  perms                   - Fix file permissions"
	@echo "  state-check             - Validate state syntax before applying"
	@echo "  clean         - Clean up test artifacts (*.json)"
	@echo "  clean-keys    - Delete test minion keys only"
	@echo "  clean-all     - Full cleanup (containers + keys + artifacts)"
	@echo ""
	@echo "Salt Discovery:"
	@echo "  salt-help              - Show Salt documentation links"
	@echo "  salt-doc               - Show all module documentation"
	@echo "  salt-doc-module        - Show docs for MODULE (make salt-doc-module MODULE=pkg)"
	@echo "  salt-grains            - Show all grains on all minions"
	@echo "  salt-grains-get        - Get specific grain (make salt-grains-get GRAIN=os)"
	@echo ""
	@echo "Salt Connectivity:"
	@echo "  salt-test-ping         - Ping all minions"
	@echo "  salt-manage-status     - Check minion connectivity status"
	@echo "  salt-key-list          - List accepted/pending minion keys"
	@echo ""
	@echo "Salt Ad-Hoc Execution:"
	@echo "  salt-cmd               - Run command on all minions (make salt-cmd CMD='uptime')"
	@echo "  salt-cmd-target        - Run on target (make salt-cmd-target TARGET='web*' CMD='df -h')"
	@echo ""
	@echo "Salt State Management:"
	@echo "  salt-state-highstate   - Apply full state to all minions"
	@echo "  salt-state-highstate-test - Dry-run full state (test mode)"
	@echo "  salt-state-apply       - Apply state to specific minion (MINION=name)"
	@echo "  salt-state-sls         - Apply specific state (make salt-state-sls STATE=linux.install)"
	@echo "  salt-state-sls-test    - Dry-run specific state"
	@echo "  salt-state-show        - Preview state parsing (make salt-state-show STATE=linux)"
	@echo ""
	@echo "Salt Jobs & Cache:"
	@echo "  salt-jobs-active       - List currently running jobs"
	@echo "  salt-jobs-list         - List recent jobs"
	@echo "  salt-jobs-clear        - Clear old jobs"
	@echo "  salt-cache-clear       - Clear Salt cache on all minions"
	@echo ""
	@echo "Examples:"
	@echo "  make test         # Run all tests sequentially"
	@echo "  make test-ubuntu  # Quick test on Ubuntu"
	@echo "  make test-rhel    # Test on Rocky Linux"
	@echo "  make test-apt     # Test apt-based systems"
	@echo "  make lint         # Check code quality"
	@echo "  make clean        # Clean test artifacts"

# =========================================================================== #
# Fixtures
# =========================================================================== #

SHELL := /bin/bash

# salt-call 
SALT_CALL = sh -c 'salt-call "$$@" 2>/dev/null || exec sudo salt-call "$$@"' --

# Generic required-argument checker (used by parameterized targets)
# Usage: make target ARGUMENT=value
# Example: make debug-minion MINION=ubuntu
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
	@echo "Mamba: Create environment"
	mamba env create -f environment.yml

mamba-update:
	@echo "Mamba: Update environment"
	mamba env update --prune -f environment.yml

mamba-remove:
	@echo "Mamba: Remove environment"
	mamba env remove -yn cozy-salt

mamba-activate:
	@echo "Mamba: Activate"
	@echo "Run: "
	@echo "   mamba activate cozy-salt"

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
	@echo "=== Quick test (no docker rebuild) ==="
	docker compose exec -t salt-minion-ubuntu-test salt-call state.highstate --out=json

# =========================================================================== #
# pytest targets
# =========================================================================== #

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



# =========================================================================== #
# Linting
# =========================================================================== #
lint: pytest-lint

# Legacy lint targets (still available for direct use)
lint-legacy: lint-shell lint-ps

lint-shell:
	@echo "=== Linting shell scripts ==="
	@if command -v shellcheck >/dev/null 2>&1; then \
		./tests/test-shellscripts.sh; \
	else \
		echo "shellcheck not installed, skipping"; \
	fi

lint-ps:
	@echo "=== Linting PowerShell scripts ==="
	@if command -v pwsh >/dev/null 2>&1; then \
		pwsh -File ./tests/test-psscripts.ps1; \
	else \
		echo "PowerShell not installed, skipping"; \
	fi

# =========================================================================== #
# Docker operations
# =========================================================================== #

# Master lifecycle
up-master:
	docker compose up -d salt-master

down-master:
	docker compose down

restart-master:
	docker compose restart salt-master

# Minion lifecycle (test containers)
up-ubuntu-test:
	docker compose --profile test-ubuntu up -d salt-minion-ubuntu

down-ubuntu-test:
	docker compose --profile test-ubuntu down

up-rhel-test:
	docker compose --profile test-rhel up -d salt-minion-rhel

down-rhel-test:
	docker compose --profile test-rhel down

up-windows-test: setup-windows-keys
	docker compose --profile test-windows up -d salt-minion-windows

down-windows-test:
	docker compose --profile test-windows down

setup-windows-keys:
	pwsh -ExecutionPolicy Bypass -File scripts/generate-windows-keys.ps1

# Aliases (up/down/restart = master only, minions require profiles)
up: up-master
down: down-master
restart: restart-master

status:
	@echo "=== Container Status ===" && docker compose ps && echo "" && echo "=== Minion Connectivity ===" && docker compose exec -t salt-master salt-run manage.status 2>/dev/null || echo "(Master not running)"

logs:
	docker compose logs -f salt-master

clean:
	@echo "=== Cleaning test artifacts... ==="
	rm -f tests/output/*.json
	docker compose --profile test-linux down 2>/dev/null || true
	docker compose --profile test-rhel down 2>/dev/null || true
	docker compose --profile test-windows down 2>/dev/null || true
	@echo "Clean complete"

clean-all: clean
	@echo "✓ Full cleanup complete"

# DEPRECATED: Keys are now baked at build time - no manual cleanup needed
# Rebuild images to get fresh keys: docker compose build
clean-keys:
	@echo "DEPRECATED: Keys are baked at build time. Rebuild to get fresh keys:"
	@echo "  docker compose build --no-cache"

# =========================================================================== #
# Utilities
# =========================================================================== #

validate:
	@echo "=== Running validation... ==="
	./scripts/fix-permissions.sh

perms:
	@echo "=== Fixing file permissions... ==="
	./scripts/fix-permissions.sh

shell:
	docker compose exec -it salt-master /bin/bash

debug-minion: require-MINION
	docker compose exec -it salt-minion-$(MINION)-test /bin/bash

logs-minion: require-MINION
	docker compose logs -f salt-minion-$(MINION)-test

state-check:
	docker compose exec -t salt-master salt-call state.show_top 2>/dev/null || echo "Error: Check state syntax in srv/salt/"

# Validate .sls files for YAML/Jinja syntax errors
# Uses containerized salt-call for consistent validation
# Note: Windows states skipped on Linux (require Windows Salt modules)
validate-states:
	@echo "=== Validating Salt state files (Linux) ==="
	@echo "(Skipping srv/salt/windows/* - requires Windows Salt)"
	@failed=0; \
	for sls in $$(find srv/salt -name "*.sls" -type f ! -path "*/windows/*"); do \
		salt_path="salt://$$(echo $$sls | sed 's|srv/salt/||')"; \
		if ! docker compose exec -T salt-master salt-call --local slsutil.renderer "$$salt_path" >/dev/null 2>&1; then \
			echo "FAIL: $$sls"; \
			docker compose exec -T salt-master salt-call --local slsutil.renderer "$$salt_path" 2>&1 | tail -5; \
			failed=$$((failed + 1)); \
		else \
			echo "  OK: $$sls"; \
		fi; \
	done; \
	if [ $$failed -gt 0 ]; then \
		echo ""; \
		echo "=== $$failed file(s) failed validation ==="; \
		exit 1; \
	else \
		echo ""; \
		echo "=== All Linux state files valid ==="; \
	fi

# Validate Windows states (run on Windows host with Salt installed)
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
		echo ""; \
		echo "=== $$failed file(s) failed validation ==="; \
		exit 1; \
	else \
		echo ""; \
		echo "=== All Windows state files valid ==="; \
	fi

# =========================================================================== #
# Salt-Master helpers
# =========================================================================== #

salt-help:
	@echo "=== Salt documentation... ==="
	@echo ""
	@echo ""
	@echo "	SaltStack documentation: https://docs.saltproject.io/"
	@echo ""
	@echo "	Table of Contents: https://docs.saltproject.io/en/latest/contents.html"
	@echo ""
	@echo "	CLI: https://docs.saltproject.io/en/latest/ref/cli/index.html"
	@echo "	API(python): https://docs.saltproject.io/en/latest/ref/clients/index.html"
	@echo "	Modules Index(python) (https://docs.saltproject.io/en/latest/py-modindex.html)"
	@echo ""
	@echo "	Architecture: https://docs.saltproject.io/en/latest/topics/topology/index.html"
	@echo ""
	@echo "	Windows documentation: https://docs.saltproject.io/en/latest/topics/windows/index.html"

# ---------------------------------------------------------------------------
# Discovery & Documentation
# ---------------------------------------------------------------------------

salt-doc:
	docker compose exec -t salt-master salt '*' sys.doc

salt-doc-module: require-MODULE
	docker compose exec -t salt-master salt '*' sys.doc $(MODULE)

# ---------------------------------------------------------------------------
# Ad-hoc Command Execution
# ---------------------------------------------------------------------------

salt-cmd: require-CMD
	docker compose exec -t salt-master salt '*' cmd.run '$(CMD)'

salt-cmd-target: require-TARGET require-CMD
	docker compose exec -t salt-master salt '$(TARGET)' cmd.run '$(CMD)'

# ---------------------------------------------------------------------------
# Grains (System Info)
# ---------------------------------------------------------------------------

salt-grains:
	docker compose exec -t salt-master salt '*' grains.items

salt-grains-get: require-GRAIN
	docker compose exec -t salt-master salt '*' grains.item $(GRAIN)

# ---------------------------------------------------------------------------
# State Management (specific states)
# ---------------------------------------------------------------------------

salt-state-sls: require-STATE
	docker compose exec -t salt-master salt '*' state.sls $(STATE)

salt-state-sls-test: require-STATE
	docker compose exec -t salt-master salt '*' state.sls $(STATE) test=true

salt-state-show: require-STATE
	docker compose exec -t salt-master salt '*' state.show_sls $(STATE)

# ---------------------------------------------------------------------------
# Cache Management
# ---------------------------------------------------------------------------

salt-cache-clear:
	docker compose exec -t salt-master salt '*' saltutil.clear_cache

# DEPRECATED: Use salt-cache-clear instead
salt-clear_cache: salt-cache-clear

salt-key-list:
	docker compose exec -t salt-master salt-key -L

salt-key-status:
	@echo "=== Minion Key Status ===" && docker compose exec -t salt-master salt-key -L

# DEPRECATED: Keys are baked at build time - this target no longer needed
salt-key-cleanup-test:
	@echo "DEPRECATED: Keys are baked at build time. Rebuild to get fresh keys."

salt-key-accept: require-NAME
	@echo "=== Accept a pending minion key ==="
	docker compose exec -t salt-master salt-key -a "$(NAME)" -y || true

salt-key-delete: require-NAME
	@echo "=== Delete a minion key ==="
	docker compose exec -t salt-master salt-key -d "$(NAME)" -y || true

salt-key-reject: require-NAME
	@echo "=== Reject a pending minion key ==="
	docker compose exec -t salt-master salt-key -r "$(NAME)" -y || true

salt-key-accept-test:
	@echo "=== Accepting pending test minion keys ==="
	docker compose exec -t salt-master salt-key -a ubuntu-test -y || true
	docker compose exec -t salt-master salt-key -a rhel-test -y || true
	docker compose exec -t salt-master salt-key -L

salt-manage-status:
	docker compose exec -t salt-master salt-run manage.status

salt-jobs-active:
	docker compose exec -t salt-master salt-run jobs.active

salt-jobs-list:
	docker compose exec -t salt-master salt-run jobs.list_jobs

salt-jobs-clear:
	docker compose exec -t salt-master salt-run jobs.clear_old_jobs 2>/dev/null || echo "No old jobs to clear"

salt-test-ping:
	docker compose exec -t salt-master salt '*' test.ping

salt-state-highstate:
	docker compose exec -t salt-master salt '*' state.highstate

salt-state-highstate-test:
	docker compose exec -t salt-master salt '*' state.highstate test=true

salt-state-apply: require-MINION
	@echo "=== Applying state to $(MINION) ==="
	docker compose exec -t salt-master salt '$(MINION)' state.highstate

salt-state-apply-test: require-MINION
	@echo "=== Testing state on $(MINION) ==="
	docker compose exec -t salt-master salt '$(MINION)' state.highstate test=true

# =========================================================================== #
# Salt-call: On host blocks
# =========================================================================== #


salt-call-ping:
	@echo "=== Test minion connectivity ==="
	$(SALT_CALL) test.ping

salt-call-highstate:
	@echo "=== Applying state ==="
	$(SALT_CALL) state.highstate --state-output=terse -l warning

salt-call-highstate-test:
	@echo "=== Test state ==="
	$(SALT_CALL) state.highstate test=True --state-output=terse -l warning

salt-call-show-top:
	@echo "=== Show which states would apply ==="
	$(SALT_CALL) state.show_top

salt-call-show-highstate:
	@echo "=== Show highstate without applying ==="
	$(SALT_CALL) state.show_highstate

salt-call-grains:
	@echo "=== Show all grains ==="
	$(SALT_CALL) grains.items

salt-call-pillar:
	@echo "=== Show all pillar data ==="
	$(SALT_CALL) pillar.items

salt-call-sync:
	@echo "=== Sync all modules from master ==="
	$(SALT_CALL) saltutil.sync_all

salt-call-refresh-pillar:
	@echo "=== Refresh pillar data ==="
	$(SALT_CALL) saltutil.refresh_pillar

salt-call-pkg-upgrades:
	@echo "=== Show available package upgrades ==="
	$(SALT_CALL) pkg.list_upgrades