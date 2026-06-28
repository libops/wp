#!/usr/bin/env bash

set -eou pipefail

# The snippet below list all the secret files referenced by the docker-compose.yml file.
# For each it will generate a random password.
readonly CHARACTERS='[A-Za-z0-9]'
readonly LENGTH=32
yq -r '.secrets[].file' docker-compose.yaml | uniq | while read -r SECRET; do
  if [ ! -f "${SECRET}" ]; then
    echo "Creating: ${SECRET}" >&2
    DIR=$(dirname "${SECRET}")
    if [ ! -d "${DIR}" ]; then
      mkdir -p "$DIR"
    fi
    (grep -ao "${CHARACTERS}" < /dev/urandom || true) | head "-${LENGTH}" | tr -d '\n' > "${SECRET}"
  fi
done

for OVERRIDE_FILE in docker-compose.override.yml docker-compose.override.yaml; do
  if [ ! -f "${OVERRIDE_FILE}" ]; then
    continue
  fi
  yq -r '.secrets[].file' "${OVERRIDE_FILE}" | uniq | while read -r SECRET; do
    if [ ! -f "${SECRET}" ]; then
      echo "Creating: ${SECRET}" >&2
      DIR=$(dirname "${SECRET}")
      if [ ! -d "${DIR}" ]; then
        mkdir -p "$DIR"
      fi
      (grep -ao "${CHARACTERS}" < /dev/urandom || true) | head "-${LENGTH}" | tr -d '\n' > "${SECRET}"
    fi
  done
done
