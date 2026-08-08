<?php

declare(strict_types=1);

$lock = json_decode(
    file_get_contents('/var/www/bedrock/composer.lock'),
    true,
    512,
    JSON_THROW_ON_ERROR,
);

foreach (array_merge($lock['packages'] ?? [], $lock['packages-dev'] ?? []) as $package) {
    if (($package['name'] ?? '') === 'roots/wordpress') {
        echo ltrim($package['version'] ?? '', 'v');
        exit(0);
    }
}

fwrite(STDERR, "roots/wordpress is absent from composer.lock\n");
exit(2);
