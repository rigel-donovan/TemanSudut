<?php

namespace App\Filament\Pages;

use App\Models\Product;
use App\Models\StockLog;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Illuminate\Database\Eloquent\Builder;
use Filament\Support\Icons\Heroicon;
use BackedEnum;

class StockManagementPage extends Page implements HasTable
{
    use InteractsWithTable;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedArchiveBox;
    protected static \UnitEnum|string|null $navigationGroup = 'Stock Management';
    protected static ?string $navigationLabel = 'Product Stock';
    protected static ?string $title = 'Product Stock';
    protected static ?int $navigationSort = 1;

    public function getView(): string
    {
        return 'filament.pages.stock-management';
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(Product::query()->with('category')->orderBy('name'))
            ->columns([
                TextColumn::make('name')
                    ->label('Produk')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('category.name')
                    ->label('Kategori')
                    ->badge()
                    ->color('gray'),
                TextColumn::make('sku')
                    ->label('SKU')
                    ->copyable()
                    ->color('gray'),
                TextColumn::make('stock')
                    ->label('Stok')
                    ->sortable()
                    ->badge()
                    ->color(fn ($record) => match(true) {
                        $record->stock <= 0   => 'danger',
                        $record->stock <= 10  => 'warning',
                        default               => 'success',
                    })
                    ->formatStateUsing(fn ($state) => $state . ' unit'),
            ])
            ->actions([
                Action::make('adjust')
                    ->label('Sesuaikan Stok')
                    ->icon('heroicon-o-pencil-square')
                    ->color('primary')
                    ->form([
                        Select::make('type')
                            ->label('Tipe')
                            ->options([
                                'in'         => '📦 Stok Masuk',
                                'out'        => '📤 Stok Keluar',
                                'adjustment' => '✏️ Koreksi Manual',
                            ])
                            ->required()
                            ->default('in')
                            ->live(),
                        TextInput::make('quantity')
                            ->label('Jumlah')
                            ->numeric()
                            ->required()
                            ->minValue(1)
                            ->helperText('Masukkan jumlah unit yang ditambah/dikurangi.'),
                        TextInput::make('reason')
                            ->label('Alasan')
                            ->placeholder('Contoh: Restok dari supplier, barang rusak, dll.')
                            ->required(),
                        Textarea::make('notes')
                            ->label('Catatan Tambahan')
                            ->rows(2)
                            ->placeholder('Opsional'),
                    ])
                    ->action(function (array $data, $record): void {
                        $qty = (int) $data['quantity'];
                        $adjustedQty = $data['type'] === 'out' ? -$qty : $qty;

                        StockLog::adjustStock(
                            productId: $record->id,
                            quantity: $adjustedQty,
                            type: $data['type'],
                            reason: $data['reason'],
                            notes: $data['notes'] ?? null,
                        );

                        Notification::make()
                            ->title('Stok berhasil diperbarui')
                            ->body("Stok {$record->name} telah disesuaikan sebesar " . ($adjustedQty > 0 ? "+$adjustedQty" : $adjustedQty) . " unit.")
                            ->success()
                            ->send();
                    }),

                Action::make('history')
                    ->label('Riwayat')
                    ->icon('heroicon-o-clock')
                    ->color('gray')
                    ->url(fn ($record) => StockLogPage::getUrl(['product' => $record->id])),
            ])
            ->emptyStateHeading('Tidak ada produk')
            ->emptyStateDescription('Tambahkan produk terlebih dahulu di menu Products.');
    }
}
