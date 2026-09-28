<?php

/**
 * Laravel Vercel Entry Point
 * Routes all requests to Laravel's public/index.php
 */

// Vercel has a read-only filesystem except /tmp
// Point Laravel's storage and cache paths to /tmp
$_ENV['LARAVEL_STORAGE_PATH'] = '/tmp/storage';
$_SERVER['LARAVEL_STORAGE_PATH'] = '/tmp/storage';
putenv('LARAVEL_STORAGE_PATH=/tmp/storage');

$_ENV['STORAGE_PATH'] = '/tmp/storage';
$_ENV['VIEW_COMPILED_PATH'] = '/tmp/views';

// Bootstrap cache paths for serverless read-only environment
$_ENV['APP_PACKAGES_CACHE'] = '/tmp/bootstrap/cache/packages.php';
$_ENV['APP_SERVICES_CACHE'] = '/tmp/bootstrap/cache/services.php';
$_ENV['APP_CONFIG_CACHE'] = '/tmp/bootstrap/cache/config.php';
$_ENV['APP_ROUTES_CACHE'] = '/tmp/bootstrap/cache/routes-v7.php';
$_ENV['APP_EVENTS_CACHE'] = '/tmp/bootstrap/cache/events.php';

putenv('APP_PACKAGES_CACHE=/tmp/bootstrap/cache/packages.php');
putenv('APP_SERVICES_CACHE=/tmp/bootstrap/cache/services.php');
putenv('APP_CONFIG_CACHE=/tmp/bootstrap/cache/config.php');
putenv('APP_ROUTES_CACHE=/tmp/bootstrap/cache/routes-v7.php');
putenv('APP_EVENTS_CACHE=/tmp/bootstrap/cache/events.php');

// Ensure writable dirs exist in /tmp
$dirs = [
    '/tmp/storage',
    '/tmp/storage/app',
    '/tmp/storage/app/public',
    '/tmp/storage/framework',
    '/tmp/storage/framework/cache',
    '/tmp/storage/framework/cache/data',
    '/tmp/storage/framework/sessions',
    '/tmp/storage/framework/views',
    '/tmp/storage/logs',
    '/tmp/views',
    '/tmp/bootstrap/cache',
];
foreach ($dirs as $dir) {
    if (!is_dir($dir)) {
        mkdir($dir, 0775, true);
    }
}

// Copy SQLite database to /tmp if it doesn't exist yet
$sqliteSrc = __DIR__ . '/../database/database.sqlite';
$sqliteDst = '/tmp/database.sqlite';
if (!file_exists($sqliteDst) && file_exists($sqliteSrc)) {
    copy($sqliteSrc, $sqliteDst);
}

// If Turso DB_URL is not configured yet, use standard SQLite in /tmp
$tursoUrl = $_ENV['DB_URL'] ?? getenv('DB_URL') ?: '';
if (empty($tursoUrl)) {
    $_ENV['DB_CONNECTION'] = 'sqlite';
    $_SERVER['DB_CONNECTION'] = 'sqlite';
    putenv('DB_CONNECTION=sqlite');

    $_ENV['DB_DATABASE'] = $sqliteDst;
    $_SERVER['DB_DATABASE'] = $sqliteDst;
    putenv('DB_DATABASE=' . $sqliteDst);
}

// Prevent Symfony/Laravel from stripping '/api' from request paths
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';

require __DIR__ . '/../public/index.php';
