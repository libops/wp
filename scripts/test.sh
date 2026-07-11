#!/usr/bin/env bash

set -eou pipefail

docker compose build --pull
docker compose run --rm init
docker compose up --remove-orphans --wait --wait-timeout "${COMPOSE_WAIT_TIMEOUT:-600}"

target_url="${SITE_URL:-http://localhost/}"
curl -fsS "${target_url}" | grep -qi "wordpress"
