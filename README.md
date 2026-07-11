# WordPress Bedrock Docker Template

The WordPress Bedrock Docker Template gives you a Docker Compose repository for running a Composer-managed [Bedrock](https://roots.io/bedrock/) WordPress site. It includes Traefik, MariaDB, and the LibOps WordPress PHP/nginx image, and is designed to be managed with [`sitectl-wp`](https://github.com/libops/sitectl-wp).

Docs:

- [Managed application architecture](https://sitectl.libops.io/apps)
- [WordPress sitectl plugin](https://sitectl.libops.io/plugins/wordpress)

## Requirements

- [sitectl](https://sitectl.libops.io/install) installed on the host that will run the site.
- [`sitectl-wp`](https://github.com/libops/sitectl-wp) installed for WordPress create, validation, healthcheck, and helper commands.
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

## Local image build

The `wp` service builds this checkout on top of the LibOps WordPress base image. Composer installs WordPress core and every plugin, theme, and must-use plugin from the lockfile. Site-owned package sources live under `packages/`; the configured Composer path repository copies them into the image instead of symlinking or copying a host-installed `web/app` tree. Local builds use the platform selected by the Docker CLI and do not push images.

Docker Compose derives the project name from the checkout directory, so independent forks do not share containers, networks, or named volumes by default. Set `COMPOSE_PROJECT_NAME` explicitly when a stable name is required. If an existing checkout previously relied on this template's fixed `wp` project name, set `COMPOSE_PROJECT_NAME=wp` before starting it to keep using its existing named volumes, or migrate those volumes deliberately.

## Basic Operations

Run these from the generated checkout, or add `--context <name>` when operating from elsewhere.

Start or update the stack with [`sitectl compose`](https://sitectl.libops.io/commands/compose):

```bash
sitectl compose up --remove-orphans -d
```

Check the site and context configuration with [`sitectl healthcheck`](https://sitectl.libops.io/commands/healthcheck) and [`sitectl validate`](https://sitectl.libops.io/commands/validate):

```bash
sitectl healthcheck
sitectl validate
```

Update the application base tag or pin that base by digest with [`sitectl image`](https://sitectl.libops.io/commands/image):

```bash
sitectl image set --tag wp=nginx-1.30.3-php84
sitectl image set --build-arg wp.BASE_IMAGE=libops/wp:nginx-1.30.3-php84@sha256:...
```

Populate the complete Composer-owned must-use plugin, plugin, and theme trees in the checkout, then enable their local development bind mounts with [`sitectl set`](https://sitectl.libops.io/commands/set):

```bash
sitectl wp composer install --no-dev
sitectl set dev-mode enabled
```

The Composer helper runs a one-shot container as the host user with the active checkout mounted at `/workspace`.
Commands such as `require`, `remove`, and `update` write changes to `composer.json` and `composer.lock` directly
into the checkout rather than a disposable application container.

Publish a domain, switch HTTP/TLS mode, configure Let's Encrypt, trust upstream proxies, or tune upload limits with the `ingress` component:

```bash
sitectl set ingress enabled --mode https-custom --domain wordpress.localhost
sitectl set ingress enabled --mode https-letsencrypt --domain wordpress.example.org --acme-email ops@example.org
sitectl set ingress enabled --trusted-ip 203.0.113.10/32 --max-upload-size 2G --upload-timeout 10m
```

`sitectl set` applies the requested component change immediately. Use `sitectl converge` when you want an interactive review of the complete component state.

The ingress component writes `INGRESS_HOSTNAMES` as comma-separated hostnames and `INGRESS_SCHEME` as `http` or `https` into the app container. Runtime config is rendered from those values during container startup, so generated sites should not carry separate app URL env vars for the same public route.

Run WordPress-specific helpers documented in the [WordPress plugin docs](https://sitectl.libops.io/plugins/wordpress):

```bash
sitectl wp cli plugin list
sitectl wp composer
sitectl wp composer require vendor/package
sitectl wp db export ./backup.sql
sitectl wp db import ./backup.sql
```

See the [WordPress sitectl plugin docs](https://sitectl.libops.io/plugins/wordpress) for WP-CLI, Composer, plugin/theme maintenance, lifecycle operations, and database helpers.

## Makefile

The Makefile is intentionally small. It only keeps WordPress-specific targets that are not core sitectl operations:

```bash
sitectl deploy
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

The `web/app/mu-plugins`, `web/app/plugins`, and `web/app/themes` directories are generated Composer installer destinations and are ignored by Git and Docker. Do not keep source code there. Put a site-owned plugin or theme in `packages/<package-name>` with its own `composer.json` and a `wordpress-plugin`, `wordpress-theme`, or `wordpress-muplugin` type, then require that package from the root project. The preconfigured `packages/*` path repository uses `symlink: false`, so both local installs and production image builds copy the package into the appropriate installer destination.

PHP `mail()` is routed through `msmtp` and relays through the Docker host by default.

With development mode disabled, rebuild and redeploy the derived site image after changing checked-in application code. Development mode deliberately mounts the complete Composer-owned must-use plugin, plugin, and theme trees, so run Composer after enabling it; an empty host tree would otherwise hide those image dependencies.

Only MariaDB and the one-shot `database-init` service receive `DB_ROOT_PASSWORD`. The initializer idempotently creates the database and scoped user before WordPress starts; the long-running app receives only `WORDPRESS_DB_PASSWORD` as `DB_PASSWORD`.

## License

The Docker Compose template and LibOps-specific setup in this repository are licensed under the MIT License. WordPress is licensed separately under the GNU General Public License v2 or later; see `LICENSE.wordpress`.

## Attribution

This template uses [Bedrock](https://roots.io/bedrock/) for Composer-managed WordPress layout and is based on the LibOps WordPress image derived from the Islandora Buildkit PHP/nginx base.
