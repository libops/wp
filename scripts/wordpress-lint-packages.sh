#!/usr/bin/env sh

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
