<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$matrix = App\Models\RolePermission::allAsMatrix();
foreach ($matrix as $feature => $roles) {
    if ($roles['cashier']) {
        echo "CASHIER HAS: $feature\n";
    } else {
        echo "CASHIER LACKS: $feature\n";
    }
}
