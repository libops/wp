ARG BASE_IMAGE=libops/wp:nginx-1.30.3-php84@sha256:cb111e41b310214b4bea8b3ee75dac2246b8845bc07e89cbe2ed6ebe89ef2d05
FROM ${BASE_IMAGE}

ARG TARGETARCH

ARG \
    # renovate: datasource=github-releases depName=wp-cli packageName=wp-cli/wp-cli
    WP_CLI_VERSION=2.12.0
ARG WP_CLI_URL=https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar
ARG WP_CLI_SHA256="ce34ddd838f7351d6759068d09793f26755463b4a4610a5a5c0a97b68220d85c"

ENV \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer
WORKDIR /var/www/bedrock

RUN if ! command -v php >/dev/null 2>&1 && command -v php84 >/dev/null 2>&1; then ln -sf "$(command -v php84)" /usr/bin/php; fi && \
    curl --fail --show-error --silent --location \
        --proto '=https' \
        --tlsv1.2 \
        "${WP_CLI_URL}" \
        --output /tmp/wp-cli.phar && \
    printf '%s  %s\n' "${WP_CLI_SHA256}" /tmp/wp-cli.phar > /tmp/wp-cli.sha256 && \
    sha256sum -c /tmp/wp-cli.sha256 && \
    install -m 0755 /tmp/wp-cli.phar /usr/local/bin/wp && \
    rm -f /tmp/wp-cli.phar /tmp/wp-cli.sha256 && \
    mkdir -p /var/www/bedrock/web/app/uploads && \
    cleanup.sh

COPY --link composer.json composer.lock /var/www/bedrock/
COPY --link packages/ /var/www/bedrock/packages/

RUN --mount=type=cache,id=custom-wp-composer-${TARGETARCH},sharing=locked,target=/tmp/composer/cache \
    composer install --working-dir=/var/www/bedrock --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader && \
    cleanup.sh

COPY --link config/ /var/www/bedrock/config/
COPY --link web/index.php web/wp-config.php /var/www/bedrock/web/

RUN chown -R nginx:nginx /var/www/bedrock
