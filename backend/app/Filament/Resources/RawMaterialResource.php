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
use Filament\Actions\EditAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;

class RawMaterialResource extends Resource
{
    protected static ?string $model = RawMaterial::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-beaker';
    protected static \UnitEnum|string|null $navigationGroup = 'Stock Management';
    protected static ?string $label = 'Raw Material';
    protected static ?string $pluralLabel = 'Raw Material';
    protected static ?int $navigationSort = 2;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Bahan Baku')
                    ->schema([
                        TextInput::make('name')
                            ->required()
                            ->maxLength(255),
                        TextInput::make('unit')
                            ->required()
                            ->placeholder('kg, gr, liter, pcs, dll.')
                            ->maxLength(255),
                        TextInput::make('stock')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        TextInput::make('min_stock')
                            ->label('Minimal Stok')
                            ->numeric()
                            ->default(0)
                            ->required(),
                        Toggle::make('is_active')
                            ->label('Aktif')
                            ->default(true),
                        FileUpload::make('image')
                            ->image()
                            ->columnSpanFull(),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\ImageColumn::make('image')
                    ->circular(),
                Tables\Columns\TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                Tables\Columns\TextColumn::make('stock')
                    ->sortable()
                    ->formatStateUsing(fn ($state, $record) => $state . ' ' . $record->unit)
                    ->color(fn ($record) => $record->stock <= $record->min_stock ? 'danger' : 'success')
                    ->weight('bold'),
                Tables\Columns\TextColumn::make('unit')
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\IconColumn::make('is_active')
                    ->label('Status')
                    ->boolean(),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
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
