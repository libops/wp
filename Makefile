.PHONY: build deps init init-if-needed up down rollout composer wp-cli db-update db-export db-import test lint

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
	docker compose run --rm init

init-if-needed: build
	./scripts/init-if-needed.sh

up: init-if-needed
	docker compose up --remove-orphans -d

down:
	docker compose down

rollout:
	./scripts/rollout.sh

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
	./scripts/lint.sh

test:
	./scripts/test.sh

%:
	@:
