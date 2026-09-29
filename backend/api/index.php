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

// Turso (libSQL) Cloud Database configuration
$tursoUrl = 'libsql://database-rigelds.aws-ap-northeast-1.turso.io';
$tursoToken = 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3OTA2MDk0MjIsImlkIjoiMDFhMGU4YTItMmIwMS03MjM4LTgxM2ItYmJjNjMzYmFmZmRjIiwia2lkIjoicFJ4LVZJWklSNG90WjBEMmZLSWttVk13b08zOWowbGlrYkNTNlFCMUpOZyIsInJpZCI6IjZlZDBhNTgzLTQwYjQtNDIxYi1hMDZmLTEyMzIxYjljZTU4ZCJ9.ogMaNyIqVKEQHf1LjyPH5dxvRsNlPDq43-gwYcqIYlpfoCS3QVIznkSqE1-0k6YGu_vaSDJJRCGPmIRnF4aqCA';

$_ENV['DB_CONNECTION'] = 'libsql';
$_SERVER['DB_CONNECTION'] = 'libsql';
putenv('DB_CONNECTION=libsql');

$_ENV['DB_URL'] = $tursoUrl;
$_SERVER['DB_URL'] = $tursoUrl;
putenv('DB_URL=' . $tursoUrl);

$_ENV['DB_AUTH_TOKEN'] = $tursoToken;
$_SERVER['DB_AUTH_TOKEN'] = $tursoToken;
putenv('DB_AUTH_TOKEN=' . $tursoToken);

// Prevent Symfony/Laravel from stripping '/api' from request paths
$_SERVER['SCRIPT_NAME'] = '/index.php';
$_SERVER['PHP_SELF'] = '/index.php';

require_once __DIR__ . '/../vendor/autoload.php';
$app = require_once __DIR__ . '/../bootstrap/app.php';

if (class_exists(\Libsql\Laravel\LibsqlServiceProvider::class)) {
    $app->register(\Libsql\Laravel\LibsqlServiceProvider::class);

    // Ensure last_insert_rowid is correctly fetched when inserting records on Turso
    $app->resolving('db', function ($db) {
        $db->extend('libsql', function ($config, $name) {
            $config = config('database.connections.libsql');
            $config['name'] = $name;
            if (!isset($config['driver'])) {
                $config['driver'] = 'libsql';
            }

            $connector = new \Libsql\Laravel\Database\LibsqlConnector();
            $dbConn = $connector->connect($config);

            $connection = new class($dbConn, $config['database'] ?? ':memory:', $config['prefix'], $config) extends \Libsql\Laravel\Database\LibsqlConnection {
                public function getDefaultPostProcessor(): \Libsql\Laravel\Database\LibsqlQueryProcessor
                {
                    return new class extends \Libsql\Laravel\Database\LibsqlQueryProcessor {
                        public function processInsertGetId(\Illuminate\Database\Query\Builder $query, $sql, $values, $sequence = null)
                        {
                            $query->getConnection()->insert($sql, $values);

                            $id = $query->getConnection()->getPdo()->lastInsertId($sequence);
                            if (empty($id) || (int) $id === 0) {
                                $row = $query->getConnection()->selectOne('SELECT last_insert_rowid() AS id');
                                $id = $row ? (is_object($row) ? ($row->id ?? 0) : ($row['id'] ?? 0)) : 0;
                            }

                            return is_numeric($id) ? (int) $id : $id;
                        }
                    };
                }
            };

            app()->instance(\Libsql\Laravel\Database\LibsqlConnection::class, $connection);
            $connection->createReadPdo($config);

            return $connection;
        });
    });
}

$app->handleRequest(\Illuminate\Http\Request::capture());

