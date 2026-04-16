<?php

namespace App\Filament\Resources\Products\Tables;

use App\Filament\Pages\StockManagementPage;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ProductsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->query(\App\Models\Product::query()->with(['category', 'ingredients.rawMaterial']))
            ->columns([
                ImageColumn::make('image')
                    ->circular()
                    ->disk('public')
                    ->toggleable(),
                TextColumn::make('name')
                    ->label('Produk')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('category.name')
                    ->label('Kategori')
                    ->badge()
                    ->color('gray')
                    ->sortable(),
                TextColumn::make('sku')
                    ->label('SKU')
                    ->searchable()
                    ->color('gray'),
                TextColumn::make('price')
                    ->label('Harga Jual')
                    ->formatStateUsing(fn ($state) => 'Rp ' . number_format($state, 0, ',', '.'))
                    ->sortable(),
                TextColumn::make('hpp')
                    ->label('HPP')
                    ->formatStateUsing(fn ($state) => $state > 0 ? 'Rp ' . number_format($state, 0, ',', '.') : '—')
                    ->color('gray')
                    ->sortable(),
                TextColumn::make('profit')
                    ->label('Profit')
                    ->formatStateUsing(fn ($record) => $record->hpp > 0 ? 'Rp ' . number_format($record->profit, 0, ',', '.') : '—')
                    ->color(fn ($record) => $record->profit > 0 ? 'success' : ($record->profit < 0 ? 'danger' : 'gray'))
                    ->sortable(query: fn ($query, string $direction) => $query->orderByRaw('(price - hpp) ' . $direction)),
                TextColumn::make('stock')
                    ->label('Stok')
                    ->sortable()
                    ->badge()
                    ->color(fn ($record) => match(true) {
                        $record->stock <= 0   => 'danger',
                        $record->stock <= 10  => 'warning',
                        default               => 'success',
                    })
                    ->formatStateUsing(fn ($state) => number_format((float)$state, 0, ',', '.') . ' porsi'),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
