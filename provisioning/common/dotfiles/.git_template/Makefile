# =========================================================================== #
# Python environment ( mamba )
# =========================================================================== #

SHELL := /bin/bash

require-%:
	@if [ -z "$($*)" ]; then \
		echo "Error: missing required argument '$*'"; \
		echo "Usage: make $*=<value> <target>"; \
		exit 1; \
	fi

mamba-create: require=-TARGET
	@echo "Mamba: Create environment"
	mamba env create -f environment.yml -n '$(TARGET)'

mamba-update: require=-TARGET
	@echo "Mamba: Update environment"
	mamba env update --prune -f environment.yml -n '$(TARGET)'

mamba-remove: require=-TARGET
	@echo "Mamba: Remove environment"
	mamba env remove -yn '$(TARGET)'

mamba-recreate: require=-TARGET
	@echo "Mamba: Remove environment"
	mamba-remove TARGET='$(TARGET)'
	mamba-create TARGET='$(TARGET)'

mamba-activate: require=-TARGET
	@echo "Mamba: Activate"
	@echo "Run: "
	@echo "   mamba activate '$(TARGET)'"
