<?php

declare(strict_types=1);

if ($argc !== 2 || $argv[1] === '') {
    fwrite(STDERR, "usage: wordpress-media-fixture.php PATH\n");
    exit(2);
}

$fixture = base64_decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    true,
);
if ($fixture === false || file_put_contents($argv[1], $fixture) === false) {
    fwrite(STDERR, "could not write the media fixture\n");
    exit(3);
}
