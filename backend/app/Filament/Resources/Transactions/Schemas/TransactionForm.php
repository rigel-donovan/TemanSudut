<?php

namespace App\Filament\Resources\Transactions\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Schema;

class TransactionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('user_id')
                    ->numeric(),
                TextInput::make('subtotal')
                    ->required()
                    ->numeric()
                    ->prefix('Rp. '),
                TextInput::make('tax')
                    ->required()
                    ->numeric()
                    ->default(0)
                    ->prefix('Rp. '),
                TextInput::make('total')
                    ->required()
                    ->numeric()
                    ->prefix('Rp. '),
                TextInput::make('payment_method'),
                TextInput::make('status')
                    ->required()
                    ->default('pending'),
                Textarea::make('notes')
                    ->columnSpanFull(),
            ]);
    }
}
