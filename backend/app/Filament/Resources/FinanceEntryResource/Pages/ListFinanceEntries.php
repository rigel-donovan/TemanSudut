<?php

namespace App\Filament\Resources\FinanceEntryResource\Pages;

use App\Filament\Resources\FinanceEntryResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListFinanceEntries extends ListRecords
{
    protected static string $resource = FinanceEntryResource::class;

    protected function getHeaderActions(): array
    {
        return [CreateAction::make()];
    }
}
