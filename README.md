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

The `wp` service builds this checkout on top of the LibOps WordPress base image. The Dockerfile copies Composer lockfiles before local plugins and themes so Docker can reuse dependency layers when only site customizations change. Local builds use the platform selected by the Docker CLI and do not push images.

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

Update image tags or pin a full image reference with [`sitectl image`](https://sitectl.libops.io/commands/image):

```bash
sitectl image set --tag wp=nginx-1.30.3-php84
sitectl image set --image wp=libops/wp:nginx-1.30.3-php84@sha256:...
```

Enable local development bind mounts with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply the component change with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set dev-mode enabled
sitectl converge
```

Switch TLS modes with the [Traefik service commands](https://sitectl.libops.io/plugins/traefik):

```bash
sitectl traefik tls mkcert --domain wordpress.localhost
sitectl traefik tls letsencrypt --email ops@example.org
```

Trust an upstream load balancer or reverse proxy with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply it with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set reverse-proxy enabled --trusted-ip 203.0.113.10/32
sitectl converge
```

Raise upload limits with [`sitectl set`](https://sitectl.libops.io/commands/set), then apply them with [`sitectl converge`](https://sitectl.libops.io/commands/converge):

```bash
sitectl set upload-limits enabled --max-upload-size 2G --upload-timeout 10m
sitectl converge
```

Run WordPress-specific helpers documented in the [WordPress plugin docs](https://sitectl.libops.io/plugins/wordpress):

```bash
sitectl wp cli plugin list
sitectl wp composer
sitectl wp db export ./backup.sql
sitectl wp db import ./backup.sql
```

See the [WordPress sitectl plugin docs](https://sitectl.libops.io/plugins/wordpress) for WP-CLI, Composer, plugin/theme maintenance, lifecycle operations, and database helpers.

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

## License

The Docker Compose template and LibOps-specific setup in this repository are licensed under the MIT License. WordPress is licensed separately under the GNU General Public License v2 or later; see `LICENSE.wordpress`.

## Attribution

This template uses [Bedrock](https://roots.io/bedrock/) for Composer-managed WordPress layout and is based on the LibOps WordPress image derived from the Islandora Buildkit PHP/nginx base.
