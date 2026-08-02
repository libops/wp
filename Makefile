SHELL := /bin/bash

.PHONY: help init up clean reconcile healthcheck test lint
.SILENT:

-include custom.Makefile

help: ## Show this help message
	echo 'Usage: make [target]'
	echo ''
	echo 'Available targets:'
	awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%s\033[0m\t%s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort | column -t -s $$'\t'

init reconcile: ## Generate or repair declared initialization state
	sitectl compose reconcile

up: ## Start the complete site and wait for health
	sitectl compose up --wait

clean: ## Delete generated local state after confirmation
	sitectl compose clean

healthcheck: ## Check Compose and application health
	sitectl healthcheck

test: ## Run template checks
	./scripts/test.sh

lint: ## Lint template files
	./scripts/lint.sh
