# WordPress Bedrock Docker Template

LibOps Docker Compose template for running a Composer-managed [Bedrock](https://roots.io/bedrock/) WordPress site with Traefik, MariaDB, and the LibOps WordPress PHP/nginx image.

## Requirements

- `sitectl` installed on the host that will run the site.
- Docker with the Compose v2 plugin installed on the same host.

## Quick start

Create a new WordPress site from this template:

```bash
sitectl create wp/default \
  --template-repo https://github.com/libops/wp \
  --path ./my-wordpress-site \
  --type local \
  --checkout-source template \
  --default-context
```

The site is served through Traefik at `http://localhost`. The first boot runs `wp-cli` automatically. The default admin account is `admin`; its password is generated in `./secrets/WORDPRESS_ADMIN_PASSWORD`.

## Basic operations with sitectl

Run these from the generated checkout, or add `--context <name>` when operating from elsewhere.

```bash
# Start or update the Compose stack
sitectl compose up --remove-orphans -d

# Check the site and context configuration
sitectl healthcheck
sitectl validate

# Update image tags or pin a full image reference
sitectl image set --tag wp=nginx-1.30.3-php84
sitectl image set --image wp=libops/wp:nginx-1.30.3-php84@sha256:...

# Enable local development bind mounts
sitectl set dev-mode enabled
sitectl converge

# Switch TLS modes
sitectl traefik tls mkcert --domain wordpress.localhost
sitectl traefik tls letsencrypt --email ops@example.org

# Trust an upstream load balancer or reverse proxy
sitectl set reverse-proxy enabled --trusted-ip 203.0.113.10/32
sitectl converge

# Raise upload limits for larger media
sitectl set upload-limits enabled --max-upload-size 2G --upload-timeout 10m
sitectl converge

# Run WordPress-specific helpers from the plugin
sitectl wp cli plugin list
sitectl wp composer
sitectl wp db export ./backup.sql
sitectl wp db import ./backup.sql
```

See the [WordPress sitectl plugin docs](https://github.com/libops/sitectl-docs/blob/main/plugins/wordpress.mdx) for WP-CLI, Composer, plugin/theme maintenance, lifecycle operations, and database helpers.

## Makefile

The Makefile is intentionally small. It only keeps WordPress-specific targets that are not core sitectl operations:

```bash
make rollout
make test
make lint
```

Use `sitectl compose ...`, `sitectl traefik ...`, and `sitectl set ...` directly for normal stack operations.

## Template notes

- `traefik` is the only published ingress.
- `wp` is built from this repository and based on the LibOps WordPress PHP/nginx image.
- `mariadb` stores application data.
- `wordpress-uploads` persists uploaded files without hiding Composer-managed dependencies.
- `composer.json` manages WordPress core and downstream plugin/theme dependencies.

Custom plugins and themes belong under `web/app/plugins`, `web/app/themes`, or `web/app/mu-plugins`. PHP `mail()` is routed through `msmtp` and relays through the Docker host by default.

## Attribution

This template uses [Bedrock](https://roots.io/bedrock/) for Composer-managed WordPress layout and is based on the LibOps WordPress image derived from the Islandora Buildkit PHP/nginx base.
