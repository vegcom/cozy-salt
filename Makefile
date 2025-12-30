# cozy-salt Makefile - shortcuts for common operations

.PHONY: help test test-ubuntu test-apt test-linux test-rhel test-windows test-all test-quick lint lint-shell lint-ps clean clean-keys clean-all up down restart logs status validate perms shell state-check debug-minion logs-minion salt-help salt-key-list salt-key-status salt-key-cleanup-test salt-key-accept salt-key-delete salt-key-reject salt-key-accept-test salt-manage-status salt-jobs-active salt-jobs-list salt-jobs-clear salt-test-ping salt-state-highstate salt-state-highstate-test


# Default target
help:
	@echo "cozy-salt - Salt infrastructure management"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "Testing:"
	@echo "  test          - Run sequential state tests (ubuntu → rhel → windows)"
	@echo "  test-ubuntu   - Test on Ubuntu 24.04 (apt-based)"
	@echo "  test-rhel     - Test on RHEL/Rocky 9 (dnf-based)"
	@echo "  test-windows  - Test on Windows (requires KVM)"
	@echo "  test-quick    - Run test without docker rebuild (faster iteration)"
	@echo "  lint          - Run all linters (shell + powershell)"
	@echo ""
	@echo "Docker/Container:"
	@echo "  up            - Start Salt Master + minions"
	@echo "  down          - Stop all containers"
	@echo "  restart       - Restart containers (quick bounce)"
	@echo "  status        - Show container + minion status"
	@echo "  logs          - View salt-master logs (streaming)"
	@echo "  shell         - Enter salt-master container (interactive bash)"
	@echo "  debug-minion  - Enter a minion container (usage: make debug-minion MINION=ubuntu)"
	@echo "  logs-minion   - Tail minion logs (usage: make logs-minion MINION=ubuntu)"
	@echo ""
	@echo "Validation/Maintenance:"
	@echo "  validate      - Run pre-commit validation (permissions + optional linting)"
	@echo "  perms         - Fix file permissions"
	@echo "  state-check   - Validate state syntax before applying"
	@echo "  clean         - Clean up test artifacts (*.json)"
	@echo "  clean-keys    - Delete test minion keys only"
	@echo "  clean-all     - Full cleanup (containers + keys + artifacts)"
	@echo ""
	@echo "Salt-Master helpers:"
	@echo "  salt-help              - Show Salt documentation links"
	@echo "  salt-test-ping         - Ping all minions (connectivity test)"
	@echo "  salt-key-list          - List accepted/pending minion keys"
	@echo "  salt-manage-status     - Check minion connectivity status"
	@echo "  salt-clear_cache       - Clear Salt cache on all minions"
	@echo "  salt-jobs-active       - List currently running jobs"
	@echo "  salt-jobs-list         - List recent jobs"
	@echo "  salt-state-highstate   - Apply full state to all minions"
	@echo "  salt-state-highstate-test - Dry-run full state (test mode)"
	@echo "  salt-state-apply       - Apply state to specific minion (MINION=name)"
	@echo "  salt-state-apply-test  - Dry-run state on specific minion (MINION=name)"
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
# Testing
# =========================================================================== #

test: test-all

test-ubuntu:
	@echo "=== Testing on Ubuntu 24.04 (apt-based) ==="
	./tests/test-states-json.sh ubuntu

test-apt: test-ubuntu

test-linux: test-ubuntu

test-rhel:
	@echo "=== Testing on RHEL/Rocky 9 (dnf-based) ==="
	./tests/test-states-json.sh rhel

test-windows:
	@echo "=== Testing on Windows (via Dockur/KVM) ==="
	./tests/test-states-json.sh windows

test-all:
	@echo "=== Testing on all distributions (sequential) ==="
	./tests/test-states-json.sh all

test-quick:
	@echo "=== Quick test (no docker rebuild) ==="
	docker compose exec -t salt-minion-ubuntu-test salt-call state.highstate --out=json



# =========================================================================== #
# Linting
# =========================================================================== #
lint: lint-shell lint-ps

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

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

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

clean-keys:
	@echo "=== Deleting test minion keys ==="
	docker compose exec -t salt-master salt-key -d ubuntu-test -y 2>/dev/null || true
	docker compose exec -t salt-master salt-key -d rhel-test -y 2>/dev/null || true
	@echo "Test keys cleaned"

clean-all: clean clean-keys
	@echo "✓ Full cleanup complete"

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
	@echo "	Windows documentaiton: https://docs.saltproject.io/en/latest/topics/windows/index.html"

salt-clear_cache:
	 docker compose exec -t salt-master salt '*' saltutil.clear_cache

salt-key-list:
	docker compose exec -t salt-master salt-key -L

salt-key-status:
	@echo "=== Minion Key Status ===" && docker compose exec -t salt-master salt-key -L

salt-key-cleanup-test:
	@echo "=== Deleting test minion keys ==="
	docker compose exec -t salt-master salt-key -d ubuntu-test -y || true
	docker compose exec -t salt-master salt-key -d rhel-test -y || true
	@echo "Test keys cleaned up"

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
	docker compose exec -t salt-master salt-run jobs.clear_old_jobs 2>/dev/null || echo "No old jobs to clear"d

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
	$(SALT_CALL) state.highstate

salt-call-highstate-test:
	@echo "=== Test state ==="
	$(SALT_CALL) state.highstate test=True

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