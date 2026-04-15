<?php

namespace App\Filament\Pages;

use App\Models\Product;
use App\Models\StockLog;
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

    /**
     * Calculate max possible servings based on ingredient stock.
     */
    public static function calculateMaxServings(Product $product): ?int
    {
        $product->loadMissing('ingredients.rawMaterial');

        if ($product->ingredients->isEmpty()) {
            return null; 
        }

        $maxServings = PHP_INT_MAX;

        foreach ($product->ingredients as $ingredient) {
            if (!$ingredient->rawMaterial || $ingredient->quantity_used <= 0) continue;

            $available = (float) $ingredient->rawMaterial->stock;
            $possible = (int) floor($available / $ingredient->quantity_used);
            $maxServings = min($maxServings, $possible);
        }

        return $maxServings === PHP_INT_MAX ? 0 : $maxServings;
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(Product::query()->with(['category', 'ingredients.rawMaterial'])->orderBy('name'))
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
                    ->formatStateUsing(fn ($state) => number_format((float)$state, 0, ',', '.') . ' porsi'),
                TextColumn::make('hpp')
                    ->label('HPP')
                    ->formatStateUsing(fn ($state) => $state > 0 ? 'Rp ' . number_format($state, 0, ',', '.') : '—')
                    ->color('gray'),
                TextColumn::make('profit')
                    ->label('Profit')
                    ->formatStateUsing(fn ($record) => $record->hpp > 0 ? 'Rp ' . number_format($record->profit, 0, ',', '.') : '—')
                    ->color(fn ($record) => $record->profit > 0 ? 'success' : ($record->profit < 0 ? 'danger' : 'gray')),
                TextColumn::make('id')
                    ->label('Stok Maks (Bahan Baku)')
                    ->formatStateUsing(function ($record) {
                        $max = self::calculateMaxServings($record);
                        if ($max === null) return '—';
                        return number_format((float)$max, 0, ',', '.') . ' porsi';
                    })
                    ->badge()
                    ->color(function ($record) {
                        $max = self::calculateMaxServings($record);
                        if ($max === null) return 'gray';
                        if ($max <= 0) return 'danger';
                        if ($max <= 10) return 'warning';
                        return 'info';
                    }),
            ])
            ->actions([
                Action::make('sync_stock')
                    ->label('Sinkron Stok')
                    ->icon('heroicon-o-arrow-path')
                    ->color('info')
                    ->requiresConfirmation()
                    ->modalHeading('Sinkron Stok dari Bahan Baku')
                    ->modalDescription(fn ($record) => $this->getSyncDescription($record))
                    ->visible(fn ($record) => $record->ingredients->isNotEmpty())
                    ->action(function ($record): void {
                        $maxServings = self::calculateMaxServings($record);
                        if ($maxServings === null) return;

                        $oldStock = $record->stock;
                        $record->update(['stock' => $maxServings]);

                        StockLog::create([
                            'product_id' => $record->id,
                            'user_id' => auth()->id(),
                            'type' => 'adjustment',
                            'quantity' => $maxServings - $oldStock,
                            'stock_before' => $oldStock,
                            'stock_after' => $maxServings,
                            'reason' => 'Sinkronisasi stok berdasarkan bahan baku',
                        ]);

                        Notification::make()
                            ->title('Stok disinkronkan')
                            ->body("Stok {$record->name}: {$oldStock} → {$maxServings} porsi")
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

    protected function getSyncDescription($record): string
    {
        $max = self::calculateMaxServings($record);
        $lines = ["Sinkronkan stok {$record->name} dari bahan baku?\n"];

        foreach ($record->ingredients as $ing) {
            if (!$ing->rawMaterial) continue;
            $rm = $ing->rawMaterial;
            $possible = (int) floor($rm->stock / $ing->quantity_used);
            $lines[] = "• {$rm->name}: {$rm->stock} {$rm->unit} ÷ {$ing->quantity_used} = {$possible} porsi";
        }

        $lines[] = "\nStok akan diubah: {$record->stock} → {$max} porsi";
        return implode("\n", $lines);
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('sync_all')
                ->label('Sinkron Semua Stok')
                ->icon('heroicon-o-arrow-path')
                ->color('info')
                ->requiresConfirmation()
                ->modalHeading('Sinkron Semua Stok Produk')
                ->modalDescription('Sinkronkan stok SEMUA produk yang punya resep bahan baku?')
                ->action(function (): void {
                    $products = Product::with('ingredients.rawMaterial')
                        ->whereHas('ingredients')
                        ->get();

                    $count = 0;
                    foreach ($products as $product) {
                        $maxServings = self::calculateMaxServings($product);
                        if ($maxServings === null) continue;

                        $oldStock = $product->stock;
                        if ($oldStock == $maxServings) continue;

                        $product->update(['stock' => $maxServings]);

                        StockLog::create([
                            'product_id' => $product->id,
                            'user_id' => auth()->id(),
                            'type' => 'adjustment',
                            'quantity' => $maxServings - $oldStock,
                            'stock_before' => $oldStock,
                            'stock_after' => $maxServings,
                            'reason' => 'Sinkronisasi stok massal berdasarkan bahan baku',
                        ]);
                        $count++;
                    }

                    Notification::make()
                        ->title('Semua stok disinkronkan')
                        ->body("$count produk telah diperbarui berdasarkan bahan baku.")
                        ->success()
                        ->send();
                }),
        ];
    }
}
