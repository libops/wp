#!/usr/bin/env sh

set -eu

fixture_path="/tmp/sitectl-verify-$$.png"
attachment=""

wp_verify() {
  wp --path=/var/www/bedrock/web/wp "$@"
}

cleanup() {
  if [ -n "$attachment" ]; then
    wp_verify post delete "$attachment" --force >/dev/null 2>&1 || true
  fi
  rm -f -- "$fixture_path"
}

trap cleanup EXIT INT TERM

php /usr/local/lib/sitectl/wordpress-media-fixture.php "$fixture_path"
attachment="$(wp_verify media import "$fixture_path" --porcelain)"
case "$attachment" in
  ''|*[!0-9]*)
    echo "media import returned an invalid attachment ID" >&2
    exit 3
    ;;
esac

test "$(wp_verify post get "$attachment" --field=ID)" = "$attachment"
wp_verify post delete "$attachment" --force >/dev/null
attachment=""
cleanup
trap - EXIT INT TERM
printf '%s\n' 'media round trip complete'
