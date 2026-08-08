<?php

declare(strict_types=1);

$uploads = wp_upload_dir(null, false);

echo wp_json_encode([
    'home' => home_url(),
    'siteurl' => site_url(),
    'uploads' => $uploads['basedir'],
    'writable' => wp_is_writable($uploads['basedir']),
]);
