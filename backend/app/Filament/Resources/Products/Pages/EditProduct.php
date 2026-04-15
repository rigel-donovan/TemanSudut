<?php

namespace App\Filament\Resources\Products\Pages;

use App\Filament\Pages\StockManagementPage;
use App\Filament\Resources\Products\ProductResource;
use Filament\Resources\Pages\EditRecord;
use Filament\Actions\DeleteAction;

class EditProduct extends EditRecord
{
    protected static string $resource = ProductResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }

    protected function afterSave(): void
    {
        // Recalculate HPP
        $this->record->calculateHpp();

        // Sync stock based on ingredients
        $maxServings = StockManagementPage::calculateMaxServings($this->record);
        if ($maxServings !== null) {
            $this->record->update(['stock' => $maxServings]);
        }
    }
}
