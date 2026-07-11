#!/usr/bin/env bash

set -euo pipefail

random_secret() {
  openssl rand -hex 32
}

generate_secret_file() {
  local secret_file="$1"
  local secret_dir owner

  [ -n "${secret_file}" ] || return 0
  secret_dir="$(dirname -- "${secret_file}")"
  install -d -m 0700 "${secret_dir}"
  owner="$(stat -c '%u:%g' "${secret_dir}")"

  if [ ! -s "${secret_file}" ]; then
    echo "Creating: ${secret_file}" >&2
    umask 077
    random_secret >"${secret_file}"
  fi

  if [ "$(id -u)" -eq 0 ]; then
    chown "${owner}" "${secret_file}"
  fi
  chmod 0600 "${secret_file}"
}

generate_compose_secrets() {
  local compose_file="$1"
  local secret

  while IFS= read -r secret; do
    generate_secret_file "${secret}"
  done < <(yq -r '(.secrets // {}) | .[] | .file' "${compose_file}")
}

generate_compose_secrets docker-compose.yaml
for override_file in docker-compose.override.yml docker-compose.override.yaml; do
  [ -f "${override_file}" ] && generate_compose_secrets "${override_file}"
done

exit 0
