#!/usr/bin/env bash

set -euo pipefail

INIT_SERVICE="${INIT_SERVICE:-init}"
INIT_PROFILE="${INIT_PROFILE:-none}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required to inspect Compose state" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse docker compose config output" >&2
  exit 1
fi

config_file="$(mktemp)"
trap 'rm -f "${config_file}"' EXIT
docker compose --profile "${INIT_PROFILE}" config --format json > "${config_file}"

needs_init=0
project="$(
  jq -r \
    --arg fallback "${COMPOSE_PROJECT_NAME:-$(basename "${PWD}")}" \
    'if (.name // "") != "" then .name else $fallback end' \
    "${config_file}"
)"
has_init="$(jq -r --arg service "${INIT_SERVICE}" '(.services // {}) | has($service)' "${config_file}")"

while IFS= read -r secret_file; do
  if [ ! -s "${secret_file}" ]; then
    echo "Init required: missing secret file ${secret_file}"
    needs_init=1
  fi
done < <(
  jq -r --arg cwd "${PWD}" '
    (.secrets // {})
    | to_entries[]
    | .value
    | select(type == "object")
    | .file? // empty
    | if startswith("/") then . else "\($cwd)/\(.)" end
  ' "${config_file}" | sort -u
)

while IFS= read -r volume_key; do
  volume_name="$(
    jq -r --arg key "${volume_key}" --arg project "${project}" '
      (.volumes[$key] // {}) as $spec
      | if ($spec | type) == "object" and (($spec.name // "") != "") then
          $spec.name
        elif ($spec | type) == "object" and ($spec.external == true) then
          $key
        elif ($spec | type) == "object" and (($spec.external | type) == "object") and (($spec.external.name // "") != "") then
          $spec.external.name
        else
          "\($project)_\($key)"
        end
    ' "${config_file}"
  )"

  if ! docker volume inspect "${volume_name}" >/dev/null 2>&1; then
    echo "Init required: missing Docker volume ${volume_name}"
    needs_init=1
  fi
done < <(
  jq -r '
    (.services // {})
    | to_entries[]
    | .value.volumes? // []
    | .[]
    | if type == "object" then
        select((.type // "volume") == "volume" and (.source // "") != "")
        | .source
      elif type == "string" and (index(":") != null) then
        split(":")[0]
        | select(. != "" and (startswith(".") | not) and (startswith("/") | not) and (startswith("~") | not))
      else
        empty
      end
  ' "${config_file}" | sort -u
)

if [ "${needs_init}" -eq 0 ]; then
  echo "Init already satisfied."
  exit 0
fi

if [ "${has_init}" != "true" ]; then
  echo "Init is required, but Compose service ${INIT_SERVICE} was not found" >&2
  exit 1
fi

docker compose --profile "${INIT_PROFILE}" run --rm "${INIT_SERVICE}"
