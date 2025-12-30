# cozy-salt Makefile - shortcuts for common operations

.PHONY: help test test-ubuntu test-apt test-linux test-rhel test-windows test-all lint lint-shell lint-ps clean up down logs salt-help salt-clear_cache salt-key-list salt-manage-status salt-jobs-active salt-jobs-list salt-test-ping salt-state-highstate salt-state-highstate-test salt-lorem

# Default target
help:
	@echo "cozy-salt - Salt infrastructure management"
	@echo ""
	@echo "Available targets:"
	@echo "  test          - Run sequential state tests (ubuntu → rhel → windows)"
	@echo "  test-ubuntu   - Test on Ubuntu 24.04 (apt-based)"
	@echo "  test-apt      - Alias for test-ubuntu"
	@echo "  test-linux    - Alias for test-ubuntu (backward compat)"
	@echo "  test-rhel     - Test on RHEL/Rocky 9 (dnf-based)"
	@echo "  test-windows  - Test on Windows (requires KVM)"
	@echo "  test-all      - Alias for 'test' (sequential)"
	@echo "  lint          - Run all linters"
	@echo "  lint-shell    - Lint shell scripts"
	@echo "  lint-ps       - Lint PowerShell scripts"
	@echo "  clean         - Clean up test artifacts"
	@echo "  up            - Start Salt Master"
	@echo "  down          - Stop all containers"
	@echo "  logs          - View Salt Master logs"
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
	@echo ""
	@echo "Examples:"
	@echo "  make test         # Run all tests sequentially"
	@echo "  make test-ubuntu  # Quick test on Ubuntu"
	@echo "  make test-rhel    # Test on Rocky Linux"
	@echo "  make test-apt     # Test apt-based systems"
	@echo "  make lint         # Check code quality"
	@echo "  make clean        # Clean test artifacts"

# Testing
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

# Linting
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

# Docker operations
up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f salt-master

# Cleanup
clean:
	@echo "=== Cleaning test artifacts... ==="
	rm -f tests/output/*.json
	docker compose --profile test-linux down 2>/dev/null || true
	docker compose --profile test-rhel down 2>/dev/null || true
	docker compose --profile test-windows down 2>/dev/null || true
	@echo "Clean complete"


# Salt-Master helpers

salt-help:
	@echo "=== Salt documentaiton... ==="
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

salt-manage-status:
	docker compose exec -t salt-master salt-run manage.status

salt-jobs-active:
	docker compose exec -t salt-master salt-run jobs.active

salt-jobs-list:
	docker compose exec -t salt-master salt-run jobs.list_jobs

salt-test-ping:
	docker compose exec -t salt-master salt '*' test.ping

salt-state-highstate:
	docker compose exec -t salt-master salt '*' state.highstate

salt-state-highstate-test:
	docker compose exec -t salt-master salt '*' state.highstate test=true


## Salt-Master template
salt-lorem:
	docker compose exec -t salt-master true