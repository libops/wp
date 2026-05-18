FROM islandora/nginx:6.2.3@sha256:1e85a1f0a222289a3079d5740ce8156d36c325c1f8477fb96806fa157cfb666b

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

EXPOSE 80

WORKDIR /var/www/bedrock

ARG \
    # renovate: datasource=repology depName=alpine_3_22/php83
    PHP_VERSION=8.3.29-r0 \
    # renovate: datasource=github-tags depName=composer packageName=composer/composer
    COMPOSER_VERSION=2.8.10

RUN apk add --no-cache \
    bash \
    curl \
    git \
    msmtp \
    php83-curl=="${PHP_VERSION}" \
    php83-gd=="${PHP_VERSION}" \
    php83-iconv=="${PHP_VERSION}" \
    php83-intl=="${PHP_VERSION}" \
    php83-mbstring=="${PHP_VERSION}" \
    php83-mysqli=="${PHP_VERSION}" \
    php83-opcache=="${PHP_VERSION}" \
    php83-phar=="${PHP_VERSION}" \
    php83-session=="${PHP_VERSION}" \
    php83-tokenizer=="${PHP_VERSION}" \
    php83-xml=="${PHP_VERSION}" \
    php83-zip=="${PHP_VERSION}" \
    unzip \
    && cleanup.sh

RUN curl -fsSL https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
    && chmod +x /usr/local/bin/wp \
    && mkdir -p /var/www/bedrock/web/app/uploads \
    && chown -R nginx:nginx /var/www/bedrock

COPY --link composer.json composer.lock /var/www/bedrock/
RUN composer install --working-dir=/var/www/bedrock --no-interaction --prefer-dist

COPY --link config /var/www/bedrock/config
COPY --link web /var/www/bedrock/web
COPY --link scripts /var/www/bedrock/scripts

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
    WP_ENV=production \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/tmp/composer \
    PHP_MAX_EXECUTION_TIME=300 \
    PHP_MAX_INPUT_TIME=300 \
    PHP_DEFAULT_SOCKET_TIMEOUT=300 \
    PHP_REQUEST_TERMINATE_TIMEOUT=300 \
    PHP_MEMORY_LIMIT=256M \
    NGINX_FASTCGI_READ_TIMEOUT=300s \
    NGINX_FASTCGI_SEND_TIMEOUT=300s \
    NGINX_FASTCGI_CONNECT_TIMEOUT=300s

COPY --link rootfs /
