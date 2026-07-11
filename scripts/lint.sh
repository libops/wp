#!/usr/bin/env bash

set -euo pipefail

service="${COMPOSE_SERVICE:-wp}"

if command -v hadolint >/dev/null 2>&1; then
  echo "Running hadolint on Dockerfiles..."
  find . -name Dockerfile -exec hadolint {} +
else
  echo "hadolint not found, skipping Dockerfile validation"
fi

if command -v json5 >/dev/null 2>&1 && [ -f renovate.json5 ]; then
  echo "Running json5 validation on renovate.json5"
  json5 --validate renovate.json5 >/dev/null
else
  echo "json5 not found or renovate.json5 missing, skipping renovate validation"
fi

if command -v shellcheck >/dev/null 2>&1; then
  find scripts -name "*.sh" -exec shellcheck {} +
else
  find scripts -name "*.sh" -exec bash -n {} +
fi

docker compose build --pull "${service}"
image_ref="$(docker compose build --print "${service}" | jq -er --arg service "${service}" '.target[$service].tags[0]')"
image_id="$(docker image inspect --format '{{.Id}}' "${image_ref}")"
if [ -z "${image_id}" ]; then
  echo "Could not resolve the built image for Compose service ${service}" >&2
  exit 1
fi

docker run --rm \
  --volume "${PWD}:/workspace:ro" \
  --workdir /workspace \
  --entrypoint sh \
  "${image_id}" \
  -lc '
    set -eu

    if [ ! -d packages ] || ! find packages -type f -name "*.php" | grep -q .; then
      echo "No local WordPress package PHP files found; skipping WordPress PHP lint."
      exit 0
    fi

    find packages -type f -name "*.php" -exec php -l {} \;

    if [ -x vendor/bin/phpcs ]; then
      vendor/bin/phpcs --standard=WordPress --extensions=php packages
    else
      echo "vendor/bin/phpcs not found, skipped WordPress coding standards."
    fi
  '
