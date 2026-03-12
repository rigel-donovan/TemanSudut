<?php

namespace App\Filament\Pages;

use App\Models\Product;
use App\Models\StockLog;
use Filament\Pages\Page;
use Filament\Tables\Columns\BadgeColumn;
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
                    ->hidden(fn () => $this->productId !== null),
                TextColumn::make('type')
                    ->label('Tipe')
                    ->badge()
                    ->formatStateUsing(fn ($state) => match($state) {
                        'in'         => 'Stok Masuk',
                        'out'        => 'Stok Keluar',
                        'adjustment' => 'Koreksi',
                        default      => $state,
                    })
                    ->color(fn ($state) => match($state) {
                        'in'  => 'success',
                        'out' => 'danger',
                        default => 'warning',
                    }),
                TextColumn::make('quantity')
                    ->label('Jumlah')
                    ->formatStateUsing(fn ($state) => ($state > 0 ? '+' : '') . $state . ' unit')
                    ->color(fn ($state) => $state > 0 ? 'success' : 'danger'),
                TextColumn::make('stock_before')
                    ->label('Stok Sebelum')
                    ->suffix(' unit')
                    ->color('gray'),
                TextColumn::make('stock_after')
                    ->label('Stok Sesudah')
                    ->suffix(' unit')
                    ->weight('bold'),
                TextColumn::make('reason')
                    ->label('Alasan')
                    ->wrap(),
                TextColumn::make('user.name')
                    ->label('Oleh')
                    ->default('System'),
            ])
            ->defaultSort('created_at', 'desc')
            ->emptyStateHeading('Belum ada riwayat stok')
            ->emptyStateDescription('Sesuaikan stok produk untuk mulai merekam riwayat.');
    }
}
