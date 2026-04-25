<?php

namespace App\Filament\Resources;

use App\Filament\Resources\FinanceEntryResource\Pages;
use App\Models\FinanceEntry;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Radio;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\BulkActionGroup;
use Illuminate\Database\Eloquent\Builder;
use BackedEnum;

class FinanceEntryResource extends Resource
{
    protected static ?string $model = FinanceEntry::class;
    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-banknotes';
    protected static ?string $navigationLabel = 'Keuangan';
    protected static ?int $navigationSort = 3;
    protected static ?string $modelLabel = 'Catatan Keuangan';
    protected static ?string $pluralModelLabel = 'Catatan Keuangan';

    public static function getNavigationGroup(): ?string
    {
        return 'Laporan';
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            Radio::make('type')
                ->label('Jenis')
                ->options([
                    'income'  => 'Pemasukan',
                    'expense' => 'Pengeluaran',
                ])
                ->inline()
                ->required()
                ->live()
                ->columnSpanFull(),

            Select::make('category')
                ->label('Kategori')
                ->options(array_merge(
                    FinanceEntry::incomeCategories(),
                    FinanceEntry::expenseCategories(),
                ))
                ->searchable()
                ->required(),

            DatePicker::make('date')
                ->label('Tanggal')
                ->required()
                ->default(now()),

            TextInput::make('description')
                ->label('Keterangan')
                ->required()
                ->maxLength(255)
                ->columnSpanFull(),

            TextInput::make('amount')
                ->label('Jumlah (Rp)')
                ->numeric()
                ->required()
                ->prefix('Rp'),

            Textarea::make('notes')
                ->label('Catatan Tambahan')
                ->rows(2)
                ->maxLength(500)
                ->columnSpanFull(),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->query(FinanceEntry::query())
            ->columns([
                TextColumn::make('date')
                    ->label('Tanggal')
                    ->date('d M Y')
                    ->sortable(),

                TextColumn::make('type')
                    ->label('Jenis')
                    ->badge()
                    ->color('gray')
                    ->formatStateUsing(fn (string $state): string => $state === 'income' ? 'Pemasukan' : 'Pengeluaran'),

                TextColumn::make('category')
                    ->label('Kategori')
                    ->badge()
                    ->color('gray'),

                TextColumn::make('description')
                    ->label('Keterangan')
                    ->limit(40)
                    ->searchable(),

                TextColumn::make('amount')
                    ->label('Jumlah')
                    ->formatStateUsing(fn ($state) => 'Rp ' . number_format($state, 0, ',', '.'))
                    ->sortable(),

                TextColumn::make('user.name')
                    ->label('Dicatat Oleh')
                    ->default('-'),
            ])
            ->filters([
                SelectFilter::make('type')
                    ->label('Jenis')
                    ->options([
                        'income'  => 'Pemasukan',
                        'expense' => 'Pengeluaran',
                    ]),
                Filter::make('this_month')
                    ->label('Bulan Ini')
                    ->query(fn (Builder $query) => $query->whereMonth('date', now()->month)->whereYear('date', now()->year))
                    ->toggle(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([DeleteBulkAction::make()]),
            ])
            ->defaultSort('date', 'desc');
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListFinanceEntries::route('/'),
            'create' => Pages\CreateFinanceEntry::route('/create'),
            'edit'   => Pages\EditFinanceEntry::route('/{record}/edit'),
        ];
    }
}
