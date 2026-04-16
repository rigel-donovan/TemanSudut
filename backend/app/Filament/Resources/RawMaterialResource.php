<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RawMaterialResource\Pages;
use App\Models\RawMaterial;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Support\Icons\Heroicon;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class RawMaterialResource extends Resource
{
    protected static ?string $model = RawMaterial::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-beaker';
    protected static \UnitEnum|string|null $navigationGroup = 'Stock Management';
    protected static ?string $label = 'Bahan Baku';
    protected static ?string $pluralLabel = 'Bahan Baku';
    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Bahan Baku')
                    ->schema([
                        TextInput::make('name')
                            ->label('Nama Bahan')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('brand')
                            ->label('Merek')
                            ->maxLength(255),
                        Toggle::make('is_active')
                            ->label('Aktif')
                            ->default(true),
                        FileUpload::make('image')
                            ->image()
                            ->disk('public')
                            ->directory('raw-materials')
                            ->columnSpanFull(),
                    ])->columns(2),

                Section::make('Satuan & Konversi')
                    ->description('Tentukan satuan besar dan kecil serta nilai konversinya')
                    ->icon('heroicon-o-scale')
                    ->schema([
                        TextInput::make('unit_large')
                            ->label('Satuan Besar')
                            ->placeholder('kg, liter, item')
                            ->required(),
                        TextInput::make('unit_small')
                            ->label('Satuan Kecil')
                            ->placeholder('gr, ml, pcs')
                            ->required(),
                        TextInput::make('conversion_value')
                            ->label('Konversi (1 besar = ? kecil)')
                            ->numeric()
                            ->default(1000)
                            ->required()
                            ->helperText('Contoh: 1 kg = 1000 gr, 1 liter = 1000 ml'),
                        TextInput::make('unit')
                            ->label('Satuan Stok')
                            ->placeholder('Satuan yg dipakai utk stok (gr, ml)')
                            ->required(),
                    ])->columns(2),

                Section::make('Harga & Stok')
                    ->icon('heroicon-o-currency-dollar')
                    ->schema([
                        TextInput::make('price_per_large_unit')
                            ->label('Harga per Satuan Besar')
                            ->numeric()
                            ->prefix('Rp')
                            ->required()
                            ->live(onBlur: true)
                            ->afterStateUpdated(function ($state, $get, $set) {
                                $conv = floatval($get('conversion_value') ?: 1);
                                $price = floatval($state ?: 0);
                                if ($conv > 0) {
                                    $set('price_per_small_unit', round($price / $conv, 4));
                                }
                            }),
                        TextInput::make('price_per_small_unit')
                            ->label('Harga per Satuan Kecil (auto)')
                            ->numeric()
                            ->prefix('Rp')
                            ->dehydrated()
                            ->helperText('Dihitung otomatis: harga besar ÷ konversi, tapi tetap bisa diedit manual'),
                        TextInput::make('stock')
                            ->label('Stok Saat Ini')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        TextInput::make('min_stock')
                            ->label('Minimal Stok')
                            ->numeric()
                            ->default(0)
                            ->required(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->circular()
                    ->disk('public'),
                Tables\Columns\TextColumn::make('name')
                    ->label('Nama')
                    ->description(fn ($record) => $record->brand)
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('stock')
                    ->label('Stok')
                    ->sortable()
                    ->formatStateUsing(fn ($state, $record) => number_format((float)$state, 0, ',', '.') . ' ' . $record->unit)
                    ->color(fn ($record) => $record->stock <= $record->min_stock ? 'danger' : 'success')
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('price_per_large_unit')
                    ->label('Harga/Besar')
                    ->money('IDR')
                    ->sortable(),
                Tables\Columns\TextColumn::make('price_per_small_unit')
                    ->label('Harga/Kecil')
                    ->formatStateUsing(fn ($state, $record) => 'Rp ' . number_format($state, 2) . '/' . ($record->unit_small ?? $record->unit))
                    ->color('gray'),
                Tables\Columns\TextColumn::make('unit_large')
                    ->label('Satuan')
                    ->formatStateUsing(fn ($state, $record) => ($state ?? '-') . ' → ' . ($record->unit_small ?? '-'))
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean(),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                Action::make('history')
                    ->label('Riwayat')
                    ->icon('heroicon-o-clock')
                    ->color('gray')
                    ->url(fn ($record) => \App\Filament\Pages\RawMaterialLogPage::getUrl(['raw_material' => $record->id])),
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListRawMaterials::route('/'),
            'create' => Pages\CreateRawMaterial::route('/create'),
            'edit' => Pages\EditRawMaterial::route('/{record}/edit'),
        ];
    }
}
