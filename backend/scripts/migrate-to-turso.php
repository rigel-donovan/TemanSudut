#!/usr/bin/env php
<?php

/**
 * Script migrasi data dari SQLite lokal ke Turso via HTTP API
 * 
 * Usage: php scripts/migrate-to-turso.php
 * 
 * Requires:
 *   TURSO_DATABASE_URL=libsql://your-db.turso.io
 *   TURSO_AUTH_TOKEN=your-token
 */

$tursoUrl = getenv('TURSO_DATABASE_URL') ?: readline('Turso Database URL (libsql://...): ');
$tursoToken = getenv('TURSO_AUTH_TOKEN') ?: readline('Turso Auth Token: ');
$sqliteFile = __DIR__ . '/../database/database.sqlite';

if (!file_exists($sqliteFile)) {
    die("❌ SQLite file not found: $sqliteFile\n");
}

// Convert libsql:// URL to HTTPS for HTTP API
$httpUrl = str_replace('libsql://', 'https://', $tursoUrl);
$apiUrl = rtrim($httpUrl, '/') . '/v2/pipeline';

echo "📦 Turso HTTP API URL: $apiUrl\n";

// Connect to local SQLite
$sqlite = new PDO("sqlite:$sqliteFile");
$sqlite->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

// Get all tables
$tables = $sqlite->query("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")->fetchAll(PDO::FETCH_COLUMN);

echo "📋 Tables found: " . implode(', ', $tables) . "\n\n";

function tursoExecute(string $apiUrl, string $token, array $requests): array
{
    $ch = curl_init($apiUrl);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode(['requests' => $requests]),
        CURLOPT_HTTPHEADER => [
            'Authorization: Bearer ' . $token,
            'Content-Type: application/json',
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        throw new RuntimeException("Turso API error (HTTP $httpCode): $response");
    }

    return json_decode($response, true);
}

// Step 1: Get CREATE TABLE statements from SQLite
echo "🔧 Recreating schema on Turso...\n";
$schemaRequests = [['type' => 'execute', 'stmt' => ['sql' => 'PRAGMA foreign_keys = OFF']]];

foreach ($tables as $table) {
    $createSql = $sqlite->query("SELECT sql FROM sqlite_master WHERE type='table' AND name='$table'")->fetchColumn();
    if ($createSql) {
        $schemaRequests[] = ['type' => 'execute', 'stmt' => ['sql' => "DROP TABLE IF EXISTS `$table`"]];
        $schemaRequests[] = ['type' => 'execute', 'stmt' => ['sql' => $createSql]];
    }
}

$schemaRequests[] = ['type' => 'close'];
tursoExecute($apiUrl, $tursoToken, $schemaRequests);
echo "✅ Schema created\n\n";

// Step 2: Migrate data table by table
foreach ($tables as $table) {
    $rows = $sqlite->query("SELECT * FROM `$table`")->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($rows)) {
        echo "⏭️  Skipping $table (empty)\n";
        continue;
    }

    echo "📤 Migrating $table (" . count($rows) . " rows)...";
    
    $batchSize = 50;
    $chunks = array_chunk($rows, $batchSize);
    
    foreach ($chunks as $chunk) {
        $requests = [];
        foreach ($chunk as $row) {
            $columns = implode(', ', array_map(fn($c) => "`$c`", array_keys($row)));
            $placeholders = implode(', ', array_fill(0, count($row), '?'));
            $values = array_values($row);
            
            $args = array_map(function ($v) {
                if (is_null($v)) return ['type' => 'null'];
                if (is_int($v)) return ['type' => 'integer', 'value' => (string)$v];
                if (is_float($v)) return ['type' => 'float', 'value' => (string)$v];
                return ['type' => 'text', 'value' => (string)$v];
            }, $values);
            
            $requests[] = [
                'type' => 'execute',
                'stmt' => [
                    'sql' => "INSERT OR IGNORE INTO `$table` ($columns) VALUES ($placeholders)",
                    'args' => $args,
                ]
            ];
        }
        $requests[] = ['type' => 'close'];
        tursoExecute($apiUrl, $tursoToken, $requests);
    }
    
    echo " ✅\n";
}

// Step 3: Restore indexes
echo "\n🔍 Recreating indexes...\n";
$indexes = $sqlite->query("SELECT sql FROM sqlite_master WHERE type='index' AND sql IS NOT NULL")->fetchAll(PDO::FETCH_COLUMN);
if (!empty($indexes)) {
    $indexRequests = array_map(fn($sql) => ['type' => 'execute', 'stmt' => ['sql' => $sql]], $indexes);
    $indexRequests[] = ['type' => 'close'];
    tursoExecute($apiUrl, $tursoToken, $indexRequests);
    echo "✅ " . count($indexes) . " indexes created\n";
}

echo "\n🎉 Migration completed successfully!\n";
echo "🔗 Database URL: $tursoUrl\n";
