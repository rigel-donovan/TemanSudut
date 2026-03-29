<?php

namespace App\Filament\Pages;

use App\Models\RawMaterial;
use App\Models\StockLog;
use Filament\Pages\Page;
use Filament\Tables\Columns\BadgeColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Support\Icons\Heroicon;
use BackedEnum;

class RawMaterialLogPage extends Page implements HasTable
{
    use InteractsWithTable;

    protected static bool $shouldRegisterNavigation = false;
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedClipboardDocumentList;
    protected static ?string $title = 'Riwayat Stok Bahan Baku';

    public ?int $rawMaterialId = null;

    public function getView(): string
    {
        return 'filament.pages.raw-material-log';
    }

    public function mount(): void
    {
        $this->rawMaterialId = request()->query('raw_material');
    }

    public function getTitle(): string
    {
        if ($this->rawMaterialId) {
            $material = RawMaterial::find($this->rawMaterialId);
            return 'Riwayat Stok: ' . ($material?->name ?? '');
        }
        return 'Riwayat Semua Stok Bahan Baku';
    }

    public function table(Table $table): Table
    {
        return $table
            ->query(
                StockLog::query()
                    ->with(['rawMaterial', 'user'])
                    ->whereNotNull('raw_material_id')
                    ->when($this->rawMaterialId, fn ($q) => $q->where('raw_material_id', $this->rawMaterialId))
                    ->latest()
            )
            ->columns([
                TextColumn::make('created_at')
                    ->label('Waktu')
                    ->dateTime('d M Y, H:i')
                    ->sortable(),
                TextColumn::make('rawMaterial.name')
                    ->label('Bahan Baku')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('user.name')
                    ->label('Oleh')
                    ->searchable(),
                TextColumn::make('type')
                    ->label('Tipe')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'in' => 'success',
                        'out', 'sale' => 'danger',
                        'adjustment' => 'warning',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'in' => 'Masuk',
                        'out' => 'Keluar',
                        'sale' => 'Penjualan',
                        'adjustment' => 'Koreksi Manual',
                        default => ucfirst($state),
                    }),
                TextColumn::make('stock_before')
                    ->label('Stok Awal')
                    ->numeric(),
                TextColumn::make('quantity')
                    ->label('Perubahan')
                    ->weight('bold')
                    ->color(fn ($record) => $record->quantity > 0 ? 'success' : 'danger')
                    ->formatStateUsing(fn ($state) => $state > 0 ? "+$state" : $state),
                TextColumn::make('stock_after')
                    ->label('Stok Akhir')
                    ->numeric(),
                TextColumn::make('reason')
                    ->label('Alasan')
                    ->limit(20)
                    ->tooltip(function (TextColumn $column): ?string {
                        $state = $column->getState();
                        if (strlen($state) <= $column->getCharacterLimit()) {
                            return null;
                        }
                        return $state;
                    }),
            ])
            ->emptyStateHeading('Tidak ada riwayat')
            ->emptyStateDescription('Belum ada perubahan stok untuk bahan baku ini.');
    }
}
