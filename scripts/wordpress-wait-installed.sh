#!/usr/bin/env sh

set -eu

attempt=0
until test -f /installed; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 150 ]; then
    echo "WordPress did not become ready for database migration within 5 minutes" >&2
    exit 1
  fi
  sleep 2
done
