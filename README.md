# WordPress Bedrock Docker Template

Dockerized deployment of a Composer-managed [Bedrock](https://roots.io/bedrock/) WordPress project based on the [Islandora Buildkit](https://github.com/Islandora-Devops/isle-buildkit) nginx base image.

## Quick Start

1. Build the application image:
```bash
docker compose build
```

2. Generate secrets:
```bash
docker compose up init
```

3. Start the site:
```bash
docker compose up -d
```

3. Access the site at `http://localhost`

The first boot runs `wp-cli` automatically. Default admin credentials:
- Username: `admin` via `WORDPRESS_ADMIN_USERNAME`
- Password: contents of `./secrets/WORDPRESS_ADMIN_PASSWORD`
- Email: `admin@example.com` via `WORDPRESS_ADMIN_EMAIL`

## Project Layout

- `composer.json` manages WordPress core and any downstream plugin/theme dependencies.
- `web/wp` is the Composer-installed WordPress core directory.
- `web/app/plugins`, `web/app/themes`, and `web/app/mu-plugins` are where downstream projects add custom code or Composer-managed packages.
- `web/app/uploads` is the only application content mounted to a named volume.
- `config/application.php` reads runtime values from `/var/run/s6/container_environment`.

## Template Scope

This template intentionally includes Bedrock and WordPress core only.

It does not ship with project-specific plugins or themes. When a project uses this template, add dependencies in `composer.json` for public packages from WPackagist, or add custom code directly under:
- `web/app/plugins/`
- `web/app/themes/`
- `web/app/mu-plugins/`

Example Composer additions for a downstream project:
```json
{
  "require": {
    "wpackagist-plugin/akismet": "*",
    "wpackagist-theme/twentytwentyfour": "*"
  }
}
```

## Local Development

Traefik is always part of the stack. In local development, `docker-compose.override-example.yaml` publishes Traefik on port `80`, so requests still flow through the same frontend proxy used elsewhere.

By default, the `wp` image is self-contained: `docker build` runs `composer install` and bakes the Bedrock app into the image. The default Compose stack does not bind-mount the host checkout into the `wp` container.

If you want live host edits in local development, copy `docker-compose.override-example.yaml` to `docker-compose.override.yaml`. That override mounts `./` to `/var/www/bedrock` in `wp`.

The only named application volume is `wordpress-uploads`, mounted at `web/app/uploads`, so uploads persist without hiding Composer-managed dependencies.

A local [Mailpit](https://mailpit.axllent.org/) service is defined in `docker-compose.override-example.yaml`. Copy it to `docker-compose.override.yaml` for local use. It exposes:
- SMTP on `localhost:1025`
- Web UI on `http://localhost:8025`

PHP `mail()` in the `wp` container is wired through `msmtp`, which relays by default to `host.docker.internal:25`. That makes the running site use the Docker host's mail server without needing a WordPress SMTP plugin for the common local/dev case.

Useful commands:
```bash
docker compose build
docker compose run --rm wp plugin list
docker compose run --rm wp theme list
make db-rewrite-uploads-urls
./scripts/test-host-postfix.sh you@example.com
```

To test delivery through Postfix running on the Docker host, the app services map `host.docker.internal` to the host gateway and PHP `mail()` relays there through `msmtp`. The helper above runs `wp_mail()` through the live site's normal WordPress mail configuration.

## Configuration

Primary runtime settings:
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `DOMAIN`
- `WORDPRESS_HOME`, `WORDPRESS_SITEURL`
- `WORDPRESS_SITE_TITLE`, `WORDPRESS_ADMIN_USERNAME`, `WORDPRESS_ADMIN_EMAIL`, `WORDPRESS_ADMIN_PASSWORD`
- `WORDPRESS_LOCALE`, `WORDPRESS_TABLE_PREFIX`, `WORDPRESS_BLOG_PUBLIC`
- `WORDPRESS_AUTH_KEY`, `WORDPRESS_SECURE_AUTH_KEY`, `WORDPRESS_LOGGED_IN_KEY`, `WORDPRESS_NONCE_KEY`
- `WORDPRESS_AUTH_SALT`, `WORDPRESS_SECURE_AUTH_SALT`, `WORDPRESS_LOGGED_IN_SALT`, `WORDPRESS_NONCE_SALT`

Secrets are generated into `./secrets/` by `scripts/generate-secrets.sh`.

## Notes

- `docker compose build` installs Composer dependencies into the image.
- `docker compose up init` generates secrets for the project.
- `make db-rewrite-uploads-urls` rewrites legacy `wp-content/uploads` URLs in WordPress content to Bedrock `app/uploads` URLs.
- The image includes both `composer` and `wp-cli` so dependency and admin tasks can stay inside the container.
- The image also includes `msmtp`; PHP `mail()` relays to `host.docker.internal:25` by default.
- The relay envelope sender is configurable with `SMTP_FROM`; if unset it defaults to `info@<DOMAIN>` with a leading `www.` stripped.
- Downstream projects should own plugin and theme selection; the template stays generic.
- Mailpit remains available as an SMTP target at `mailpit:1025` when a project wants application-level SMTP testing instead of host relay.

## TLS Deployment

The base compose stack always includes Traefik for HTTP routing. To enable HTTPS and Let's Encrypt, layer in `docker-compose.tls.yml`:

```bash
docker compose -f docker-compose.yaml -f docker-compose.tls.yml up -d
```

Requirements:
- `DOMAIN` must be set to the site hostname
- `ACME_EMAIL` must be set for Let's Encrypt registration

The base compose stack publishes port `80`. With the TLS file included, Traefik also listens on `443`, redirects HTTP to HTTPS, and terminates TLS for the `wp` service. The repo keeps Traefik dynamic config in `./conf/traefik/wordpress.tmpl`, which Compose mounts into the container as a file-provider `.yml` config.

A production systemd unit example is available at `deploy/wordpress-bedrock.service`. Adjust `WorkingDirectory` and `EnvironmentFile` for the deployment host before installing it under `/etc/systemd/system/`.

