<?php

namespace App\Filament\Pages;

use App\Models\RolePermission;
use Database\Seeders\RolePermissionSeeder;
use BackedEnum;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Support\Icons\Heroicon;

use Livewire\Attributes\Rule;

class RolePermissionsPage extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedKey;

    protected static ?string $navigationLabel = 'Role Access';

    protected static ?string $title = 'Kelola Role Access Karyawan';

    protected static ?int $navigationSort = 6;

    public function getView(): string
    {
        return 'filament.pages.role-permissions';
    }

    #[Rule(['permissions.*.*' => 'boolean'])]
    public array $permissions = [];

    public function mount(): void
    {
        $this->loadPermissions();
    }

    protected function loadPermissions(): void
    {
        $matrix = RolePermission::allAsMatrix();

        foreach (RolePermissionSeeder::$features as $key => $config) {
            $this->permissions[$key] = [
                'owner'   => (bool)($matrix[$key]['owner'] ?? $config['owner']),
                'cashier' => (bool)($matrix[$key]['cashier'] ?? $config['cashier']),
            ];
        }
    }

    public function save(): void
    {
        foreach ($this->permissions as $feature => $roles) {
            foreach (['owner', 'cashier'] as $role) {
                RolePermission::updateOrCreate(
                    ['feature' => $feature, 'role' => $role],
                    ['enabled' => (bool)($roles[$role] ?? false)]
                );
            }
        }

        Notification::make()
            ->title('Berhasil disimpan!')
            ->body('Pengaturan role access telah diperbarui.')
            ->success()
            ->send();
    }
}
