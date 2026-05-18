#!/usr/bin/env bash

set -eou pipefail

max_attempts=20
attempt=0

while [ $attempt -lt $max_attempts ]; do
  attempt=$(( attempt + 1 ))
  echo "Attempt $attempt of $max_attempts..."

  sleep 10

  if curl -sf http://localhost/ | grep -qi "wordpress"; then
    echo "WordPress is up!"
    exit 0
  fi
  sleep 20
  docker compose logs wordpress --tail 20
 done

docker compose logs wordpress

echo "Failed to detect WordPress after $max_attempts attempts"
exit 1
