# syntax=docker/dockerfile:1.20.0
ARG BASE_IMAGE=libops/wp:php83
FROM ${BASE_IMAGE}

ARG TARGETARCH

ENV \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer
WORKDIR /var/www/bedrock

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp && \
    mkdir -p /var/www/bedrock/web/app/uploads && \
    cleanup.sh

COPY --link composer.json composer.lock /var/www/bedrock/

RUN --mount=type=cache,id=custom-wp-composer-${TARGETARCH},sharing=locked,target=/tmp/composer/cache \
    composer install --working-dir=/var/www/bedrock --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader && \
    cleanup.sh

COPY --link web/app/plugins/ /var/www/bedrock/web/app/plugins/
COPY --link web/app/themes/ /var/www/bedrock/web/app/themes/

ENV \
    DB_HOST=mariadb \
    DB_PORT=3306 \
    DB_NAME=wordpress \
    DB_USER=wordpress \
    DB_PASSWORD=changeme \
    WORDPRESS_HOME=http://localhost \
    WORDPRESS_SITEURL=http://localhost/wp \
    WORDPRESS_SITE_TITLE=WordPress \
    WORDPRESS_ADMIN_USERNAME=admin \
    WORDPRESS_ADMIN_EMAIL=admin@example.com \
    WORDPRESS_ADMIN_PASSWORD=changeme \
    WORDPRESS_LOCALE=en_US \
    WORDPRESS_TABLE_PREFIX=wp_ \
    WORDPRESS_BLOG_PUBLIC=0 \
    WORDPRESS_ENABLE_HTTPS=false \
    WORDPRESS_AUTH_KEY=changeme \
    WORDPRESS_SECURE_AUTH_KEY=changeme \
    WORDPRESS_LOGGED_IN_KEY=changeme \
    WORDPRESS_NONCE_KEY=changeme \
    WORDPRESS_AUTH_SALT=changeme \
    WORDPRESS_SECURE_AUTH_SALT=changeme \
    WORDPRESS_LOGGED_IN_SALT=changeme \
    WORDPRESS_NONCE_SALT=changeme \
    LIBOPS_SMTP_HOST=host.docker.internal \
    LIBOPS_SMTP_PORT=25 \
    SMTP_FROM= \
    WP_ENV=production

RUN chown -R nginx:nginx /var/www/bedrock
