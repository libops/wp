SHELL := /bin/bash

.PHONY: help rollout test lint
.SILENT:

-include custom.Makefile

help: ## Show this help message
	echo 'Usage: make [target]'
	echo ''
	echo 'Available targets:'
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%s\033[0m\t%s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort | column -t -s $$'\t'

rollout: ## Roll out the currently checked out WordPress stack
	./scripts/rollout.sh

test: ## Run template checks
	./scripts/test.sh

lint: ## Lint template files
	./scripts/lint.sh
