<?php

$root_dir = dirname(__DIR__);
$webroot_dir = $root_dir . '/web';

function s6_env($name, $default = '') {
    $path = '/var/run/s6/container_environment/' . $name;
    if (is_readable($path)) {
        return rtrim((string) file_get_contents($path), "\r\n");
    }
    return $default;
}

define('WP_ENV', s6_env('WP_ENV', 'production'));
define('WP_HOME', s6_env('WORDPRESS_HOME', 'http://localhost'));
define('WP_SITEURL', s6_env('WORDPRESS_SITEURL', WP_HOME . '/wp'));

define('DB_NAME', s6_env('DB_NAME', 'wordpress'));
define('DB_USER', s6_env('DB_USER', 'wordpress'));
define('DB_PASSWORD', s6_env('DB_PASSWORD', 'changeme'));
define('DB_HOST', s6_env('DB_HOST', 'mariadb') . ':' . s6_env('DB_PORT', '3306'));
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = s6_env('WORDPRESS_TABLE_PREFIX', 'wp_');

define('AUTH_KEY', s6_env('WORDPRESS_AUTH_KEY', 'changeme'));
define('SECURE_AUTH_KEY', s6_env('WORDPRESS_SECURE_AUTH_KEY', 'changeme'));
define('LOGGED_IN_KEY', s6_env('WORDPRESS_LOGGED_IN_KEY', 'changeme'));
define('NONCE_KEY', s6_env('WORDPRESS_NONCE_KEY', 'changeme'));
define('AUTH_SALT', s6_env('WORDPRESS_AUTH_SALT', 'changeme'));
define('SECURE_AUTH_SALT', s6_env('WORDPRESS_SECURE_AUTH_SALT', 'changeme'));
define('LOGGED_IN_SALT', s6_env('WORDPRESS_LOGGED_IN_SALT', 'changeme'));
define('NONCE_SALT', s6_env('WORDPRESS_NONCE_SALT', 'changeme'));

define('WP_CONTENT_DIR', $webroot_dir . '/app');
define('WP_CONTENT_URL', WP_HOME . '/app');
define('FS_METHOD', 'direct');
define('DISALLOW_FILE_EDIT', true);
define('AUTOMATIC_UPDATER_DISABLED', true);

define('WP_DEBUG', WP_ENV !== 'production');
define('WP_DEBUG_LOG', WP_ENV !== 'production');
define('WP_DEBUG_DISPLAY', false);

if (
    isset($_SERVER['HTTP_X_FORWARDED_PROTO']) &&
    $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https'
) {
    $_SERVER['HTTPS'] = 'on';
}

if (!defined('ABSPATH')) {
    define('ABSPATH', $webroot_dir . '/wp/');
}
