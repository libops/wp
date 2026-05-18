#!/usr/bin/env bash

set -euo pipefail

log_file="${ROLLOUT_LOG:-$(pwd)/rollout.log}"
exec > >(tee -a "${log_file}") 2>&1

checkout_ref() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return
  fi

  local target_ref="${GIT_REF:-${GIT_BRANCH:-${DOCKER_COMPOSE_BRANCH:-main}}}"
  echo "Checking out ${target_ref}"
  git fetch origin "${target_ref}" || git fetch origin
  git checkout "${target_ref}" || git checkout FETCH_HEAD
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "HEAD" ]; then
    git pull --ff-only || true
  fi
}

checkout_ref

docker compose pull --ignore-buildable --quiet || docker compose pull --ignore-buildable || true
docker compose build --pull
./scripts/init-if-needed.sh
docker compose up --remove-orphans --wait --pull missing --quiet-pull -d

docker compose exec -T wp wp --allow-root --path=/var/www/bedrock/web/wp core update-db || echo "WordPress database update skipped or failed"
docker compose exec -T wp wp --allow-root --path=/var/www/bedrock/web/wp cache flush || true

docker compose up --remove-orphans --wait --pull missing --quiet-pull -d

echo "Rollout complete"
