<?php

namespace App\Filament\Pages;

use App\Models\Product;
use App\Models\StockLog;
use Filament\Pages\Page;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Support\Icons\Heroicon;
use BackedEnum;

class StockLogPage extends Page implements HasTable
{
    use InteractsWithTable;

    protected static bool $shouldRegisterNavigation = false;
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentList;
    protected static ?string $title = 'Riwayat Stok';

    public ?int $productId = null;

    public function getView(): string
    {
        return 'filament.pages.stock-log';
    }

    public function mount(): void
    {
        $this->productId = request()->query('product');
    }

    public function getTitle(): string
    {
        if ($this->productId) {
            $product = Product::find($this->productId);
            return 'Riwayat Stok: ' . ($product?->name ?? '');
        }
        return 'Riwayat Semua Stok';
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                StockLog::query()
                    ->with(['product', 'user'])
                    ->when($this->productId, fn ($q) => $q->where('product_id', $this->productId))
                    ->whereNotNull('product_id')
                    ->latest()
            )
            ->columns([
                TextColumn::make('created_at')
                    ->label('Waktu')
                    ->dateTime('d M Y, H:i')
                    ->sortable(),
                TextColumn::make('product.name')
                    ->label('Produk')
                    ->searchable()
                    ->sortable()
                    ->hidden(fn () => $this->productId !== null),
                TextColumn::make('user.name')
                    ->label('Oleh')
                    ->searchable(),
                TextColumn::make('type')
                    ->label('Tipe')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'in' => 'success',
                        'out', 'order_deduction' => 'danger',
                        'adjustment' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'in' => 'Masuk',
                        'out' => 'Keluar',
                        'order_deduction' => 'Pesanan',
                        'adjustment' => 'Sinkronisasi',
                        default => ucfirst($state),
                    }),
                TextColumn::make('stock_before')
                    ->label('Stok Awal')
                    ->formatStateUsing(fn ($state) => number_format((float)$state, 0, ',', '.')),
                TextColumn::make('quantity')
                    ->label('Perubahan')
                    ->weight('bold')
                    ->color(fn ($record) => $record->quantity > 0 ? 'success' : 'danger')
                    ->formatStateUsing(fn ($state) => ($state > 0 ? '+' : '') . number_format((float)$state, 0, ',', '.')),
                TextColumn::make('stock_after')
                    ->label('Stok Akhir')
                    ->formatStateUsing(fn ($state) => number_format((float)$state, 0, ',', '.')),
                TextColumn::make('reason')
                    ->label('Alasan')
                    ->limit(30)
                    ->tooltip(function (TextColumn $column): ?string {
                        $state = $column->getState();
                        if (strlen($state) <= $column->getCharacterLimit()) {
                            return null;
                        }
                        return $state;
                    }),
            ])
            ->defaultSort('created_at', 'desc')
            ->emptyStateHeading('Belum ada riwayat stok')
            ->emptyStateDescription('Riwayat perubahan stok produk akan muncul di sini.');
    }
}
