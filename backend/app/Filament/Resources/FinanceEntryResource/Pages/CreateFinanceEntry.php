<?php

namespace App\Filament\Resources\FinanceEntryResource\Pages;

use App\Filament\Resources\FinanceEntryResource;
use Filament\Resources\Pages\CreateRecord;

class CreateFinanceEntry extends CreateRecord
{
    protected static string $resource = FinanceEntryResource::class;

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['user_id'] = auth()->id();
        return $data;
    }

    protected function getRedirectUrl(): string
    {
        return $this->getResource()::getUrl('index');
    }
}
