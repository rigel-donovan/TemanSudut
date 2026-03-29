<?php

namespace App\Filament\Pages;

use BackedEnum;
use Filament\Pages\Page;
use Filament\Support\Icons\Heroicon;

class BackupPage extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCircleStack;
    protected static ?string $navigationLabel = 'Backup Data';
    protected static ?string $title = 'Backup Data';
    protected static ?int $navigationSort = 99;

    public function getView(): string
    {
        return 'filament.pages.backup-page';
    }

    public function getHeaderActions(): array
    {
        return [];
    }
}
