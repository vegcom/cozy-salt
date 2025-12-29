# cozy-salt Makefile - shortcuts for common operations

.PHONY: help test test-ubuntu test-apt test-linux test-rhel test-windows test-all lint lint-shell lint-ps clean up down logs

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
	@echo "Cleaning test artifacts..."
	rm -f tests/output/*.json
	docker compose --profile test-linux down 2>/dev/null || true
	docker compose --profile test-rhel down 2>/dev/null || true
	docker compose --profile test-windows down 2>/dev/null || true
	@echo "Clean complete"
