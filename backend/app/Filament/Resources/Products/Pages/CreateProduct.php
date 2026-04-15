<?php

namespace App\Filament\Resources\Products\Pages;

use App\Filament\Pages\StockManagementPage;
use App\Filament\Resources\Products\ProductResource;
use Filament\Resources\Pages\CreateRecord;

class CreateProduct extends CreateRecord
{
    protected static string $resource = ProductResource::class;

    protected function afterCreate(): void
    {
        $this->record->calculateHpp();

        // Sync stock based on ingredients
        $maxServings = StockManagementPage::calculateMaxServings($this->record);
        $this->record->update(['stock' => $maxServings ?? 0]);
    }

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        $data['stock'] = 0;
        return $data;
    }
}
