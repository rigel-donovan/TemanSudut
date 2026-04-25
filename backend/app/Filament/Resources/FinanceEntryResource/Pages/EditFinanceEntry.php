<?php

namespace App\Filament\Resources\FinanceEntryResource\Pages;

use App\Filament\Resources\FinanceEntryResource;
use Filament\Resources\Pages\EditRecord;
use Filament\Actions\DeleteAction;

class EditFinanceEntry extends EditRecord
{
    protected static string $resource = FinanceEntryResource::class;

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
