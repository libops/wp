#!/command/with-contenv bash
# shellcheck shell=bash

set -eou pipefail

function mysql_create_database {
    cat <<-SQL | create-database.sh
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* to '${DB_USER}'@'%';
FLUSH PRIVILEGES;

SET PASSWORD FOR ${DB_USER}@'%' = PASSWORD('${DB_PASSWORD}')
SQL
}

function wp_cli {
    wp --allow-root --path=/var/www/bedrock/web/wp "$@"
}

function wait_for_wordpress_files {
    local attempts=0
    while [ ! -f /var/www/bedrock/web/wp/wp-load.php ]; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 120 ]; then
            echo "Composer-managed WordPress files were not installed in time"
            exit 1
        fi
        sleep 1
    done
}

function wait_for_database {
    local attempts=0
    until mysql -h"${DB_HOST}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" -e 'SELECT 1' >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 60 ]; then
            echo "Database was not ready in time"
            exit 1
        fi
        sleep 2
    done
}

function check_wordpress_installed {
    wp_cli core is-installed >/dev/null 2>&1
}

function install_wordpress {
    if check_wordpress_installed; then
        echo "WordPress is already installed."
        return 0
    fi

    echo "WordPress not installed. Running wp-cli installation..."
    wp_cli core install \
        --url="${WORDPRESS_HOME}" \
        --title="${WORDPRESS_SITE_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USERNAME}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email

    wp_cli option update permalink_structure '/%postname%/'
    wp_cli option update blog_public "${WORDPRESS_BLOG_PUBLIC}"

    if [ "${WORDPRESS_LOCALE}" != "en_US" ]; then
        wp_cli language core install "${WORDPRESS_LOCALE}" || true
        wp_cli site switch-language "${WORDPRESS_LOCALE}" || true
    fi

    if check_wordpress_installed; then
        echo "=========================================="
        echo "WordPress installation complete!"
        echo "=========================================="
    else
        echo "=========================================="
        echo "WordPress installation failed!"
        echo "=========================================="
        exit 1
    fi
}

function main {
    wait_for_wordpress_files
    if [ "${DB_HOST}" = "mariadb" ]; then
        mysql_create_database
    fi
    wait_for_database
    install_wordpress
    touch /installed
}
main
