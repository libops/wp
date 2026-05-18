.PHONY: build deps init up composer wp-cli db-update db-export db-import test lint

DOCKER_IMAGE=ghcr.io/libops/wordpress-bedrock:main
DB_DUMP ?= /tmp/wp.sql
DB_DUMP_ABS := $(abspath $(DB_DUMP))
DB_DUMP_DIR := $(dir $(DB_DUMP_ABS))
DB_DUMP_FILE := $(notdir $(DB_DUMP_ABS))

deps:
	docker compose pull --ignore-buildable

build: deps
	docker compose build

init: build
	docker compose up init

up: build
	docker compose up -d traefik mariadb wp

composer: build
	docker compose exec wp composer install --no-interaction

wp-cli: build
	docker compose exec wp wp --allow-root --path=/var/www/bedrock/web/wp $(filter-out $@,$(MAKECMDGOALS))

db-update: build
	docker compose exec wp wp --allow-root --path=/var/www/bedrock/web/wp core update-db

db-export: build
	mkdir -p "$(DB_DUMP_DIR)"
	docker compose exec wp wp --allow-root --path=/var/www/bedrock/web/wp db export "/tmp/$(DB_DUMP_FILE)"
	docker compose cp wp:/tmp/$(DB_DUMP_FILE) "$(DB_DUMP_ABS)"

db-import: build
	test -f "$(DB_DUMP_ABS)"
	docker compose cp "$(DB_DUMP_ABS)" wp:/tmp/$(DB_DUMP_FILE)
	docker compose exec wp wp --allow-root --path=/var/www/bedrock/web/wp db import "/tmp/$(DB_DUMP_FILE)"

lint:
	@docker compose config --format json | jq -e .services.wp.image | grep libops
	@if command -v hadolint > /dev/null 2>&1; then 		echo "Running hadolint on Dockerfiles..."; 		find . -name "Dockerfile" | xargs hadolint; 	else 		echo "hadolint not found, skipping Dockerfile validation"; 	fi
	@if command -v json5 > /dev/null 2>&1; then 		echo "Running json5 validation on renovate.json5"; 		json5 --validate renovate.json5 > /dev/null; 	else 		echo "json5 not found, skipping renovate validation"; 	fi

test: up
	./scripts/test.sh

%:
	@:
