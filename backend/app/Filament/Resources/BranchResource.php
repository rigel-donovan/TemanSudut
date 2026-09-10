<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BranchResource\Pages;
use App\Models\Branch;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductIngredient;
use App\Models\RawMaterial;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Support\Facades\DB;

class BranchResource extends Resource
{
    protected static ?string $model = Branch::class;

    protected static bool $isScopedToTenant = false;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-building-storefront';

    protected static ?string $navigationLabel = 'Kelola Cabang';

    protected static ?string $modelLabel = 'Cabang';

    protected static ?string $pluralModelLabel = 'Cabang';

    protected static ?int $navigationSort = 6;

    public static function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Cabang')
                    ->schema([
                        TextInput::make('name')
                            ->label('Nama Cabang')
                            ->placeholder('contoh: Cabang Ring Road, Cabang BDS')
                            ->required()
                            ->maxLength(255),

                        TextInput::make('phone')
                            ->label('No. Telepon / WhatsApp')
                            ->tel()
                            ->maxLength(50),

                        TextInput::make('address')
                            ->label('Alamat Lengkap')
                            ->maxLength(500)
                            ->columnSpanFull(),

                        Toggle::make('is_active')
                            ->label('Status Aktif')
                            ->default(true),
                    ])
                    ->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')
                    ->label('ID')
                    ->sortable(),

                TextColumn::make('name')
                    ->label('Nama Cabang')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),

                TextColumn::make('address')
                    ->label('Alamat')
                    ->limit(40)
                    ->placeholder('-'),

                TextColumn::make('phone')
                    ->label('Telepon')
                    ->placeholder('-'),

                TextColumn::make('products_count')
                    ->label('Total Produk')
                    ->counts('products')
                    ->badge()
                    ->color('info'),

                IconColumn::make('is_active')
                    ->label('Aktif')
                    ->boolean(),

                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime('d M Y')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Action::make('cloneCatalog')
                    ->label('Salin Menu')
                    ->icon('heroicon-o-document-duplicate')
                    ->color('success')
                    ->tooltip('Salin semua kategori dan menu dari cabang lain ke cabang ini (stok diset 0)')
                    ->form([
                        Select::make('source_branch_id')
                            ->label('Pilih Cabang Sumber')
                            ->options(fn (Branch $record) => Branch::where('id', '!=', $record->id)->pluck('name', 'id'))
                            ->required()
                            ->helperText('Seluruh kategori, produk, dan resep bahan baku akan disalin ke cabang ini.'),
                    ])
                    ->action(function (Branch $record, array $data): void {
                        $sourceId = $data['source_branch_id'];
                        $sourceBranch = Branch::find($sourceId);

                        if (!$sourceBranch) {
                            Notification::make()->danger()->title('Cabang sumber tidak ditemukan.')->send();
                            return;
                        }

                        DB::beginTransaction();
                        try {
                            // 1. Categories
                            $sourceCategories = Category::where('branch_id', $sourceId)->get();
                            $catMap = [];
                            foreach ($sourceCategories as $cat) {
                                $newCat = Category::firstOrCreate(
                                    ['branch_id' => $record->id, 'name' => $cat->name],
                                    [
                                        'slug' => $cat->slug . '-b' . $record->id,
                                        'description' => $cat->description,
                                        'image' => $cat->image,
                                        'is_active' => $cat->is_active,
                                    ]
                                );
                                $catMap[$cat->id] = $newCat->id;
                            }

                            // 2. Raw Materials
                            $sourceMaterials = RawMaterial::where('branch_id', $sourceId)->get();
                            $matMap = [];
                            foreach ($sourceMaterials as $mat) {
                                $newMat = RawMaterial::firstOrCreate(
                                    ['branch_id' => $record->id, 'name' => $mat->name],
                                    [
                                        'brand' => $mat->brand,
                                        'stock' => 0,
                                        'unit' => $mat->unit,
                                        'unit_large' => $mat->unit_large,
                                        'unit_small' => $mat->unit_small,
                                        'conversion_value' => $mat->conversion_value,
                                        'price_per_large_unit' => $mat->price_per_large_unit,
                                        'price_per_small_unit' => $mat->price_per_small_unit,
                                        'min_stock' => $mat->min_stock,
                                        'is_active' => $mat->is_active,
                                        'image' => $mat->image,
                                    ]
                                );
                                $matMap[$mat->id] = $newMat->id;
                            }

                            // 3. Products & Ingredients
                            $sourceProducts = Product::where('branch_id', $sourceId)->with('ingredients')->get();
                            $count = 0;
                            foreach ($sourceProducts as $prod) {
                                $newCatId = $catMap[$prod->category_id] ?? null;
                                $newProd = Product::create([
                                    'branch_id' => $record->id,
                                    'category_id' => $newCatId,
                                    'name' => $prod->name,
                                    'slug' => $prod->slug ? ($prod->slug . '-b' . $record->id) : null,
                                    'description' => $prod->description,
                                    'sku' => $prod->sku ? ($prod->sku . '-b' . $record->id) : null,
                                    'price' => $prod->price,
                                    'hpp' => $prod->hpp,
                                    'stock' => 0,
                                    'image' => $prod->image,
                                    'is_active' => $prod->is_active,
                                ]);

                                foreach ($prod->ingredients as $ing) {
                                    if (isset($matMap[$ing->raw_material_id])) {
                                        ProductIngredient::create([
                                            'product_id' => $newProd->id,
                                            'raw_material_id' => $matMap[$ing->raw_material_id],
                                            'quantity_used' => $ing->quantity_used,
                                        ]);
                                    }
                                }
                                $count++;
                            }

                            DB::commit();

                            Notification::make()
                                ->success()
                                ->title("Katalog Berhasil Disalin!")
                                ->body("{$count} produk dan resep telah disalin dari {$sourceBranch->name} ke {$record->name} dengan stok awal 0.")
                                ->send();
                        } catch (\Exception $e) {
                            DB::rollBack();
                            Notification::make()
                                ->danger()
                                ->title('Gagal menyalin katalog')
                                ->body($e->getMessage())
                                ->send();
                        }
                    }),
                EditAction::make(),
                static::getDeleteBranchAction(),
            ])
            ->bulkActions([
                // Bulk delete dinonaktifkan demi keamanan data cabang
            ]);
    }

    public static function getDeleteBranchAction(): Action
    {
        return Action::make('deleteBranch')
            ->label('Hapus Cabang')
            ->icon('heroicon-o-trash')
            ->color('danger')
            ->requiresConfirmation()
            ->modalHeading(fn (Branch $record) => "Hapus Cabang: {$record->name}")
            ->modalDescription(function (Branch $record) {
                $summary = $record->getDataSummary();
                $totalData = array_sum($summary);

                if ($totalData > 0) {
                    $items = [
                        ['label' => 'Produk', 'count' => $summary['products']],
                        ['label' => 'Riwayat Transaksi', 'count' => $summary['transactions']],
                        ['label' => 'Kategori Menu', 'count' => $summary['categories']],
                        ['label' => 'Bahan Baku', 'count' => $summary['raw_materials']],
                        ['label' => 'Meja', 'count' => $summary['tables']],
                        ['label' => 'Shift Kasir', 'count' => $summary['shifts']],
                        ['label' => 'Catatan Keuangan', 'count' => $summary['finance_entries']],
                    ];

                    $gridHtml = '';
                    foreach ($items as $item) {
                        if ($item['count'] > 0) {
                            $gridHtml .= "
                                <div style='background: rgba(255, 255, 255, 0.04); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 8px; padding: 6px 10px; display: flex; justify-content: space-between; align-items: center;'>
                                    <span style='font-size: 12px; color: #d1d5db;'>{$item['label']}</span>
                                    <span style='font-weight: 700; font-size: 12px; color: #fca5a5; background: rgba(239, 68, 68, 0.25); padding: 1px 8px; border-radius: 9999px;'>{$item['count']}</span>
                                </div>";
                        }
                    }

                    return new \Illuminate\Support\HtmlString("
                        <div style='text-align: left; margin: 4px 0 14px 0;'>
                            <div style='background: rgba(239, 68, 68, 0.08); border: 1px solid rgba(239, 68, 68, 0.28); border-radius: 12px; padding: 14px 16px; margin-bottom: 12px;'>
                                <div style='display: flex; align-items: center; gap: 8px; margin-bottom: 12px;'>
                                    <div style='display: flex; align-items: center; justify-content: center; width: 26px; height: 26px; border-radius: 6px; background: rgba(239, 68, 68, 0.2); color: #f87171; font-size: 14px; flex-shrink: 0;'>
                                        ⚠️
                                    </div>
                                    <div>
                                        <div style='font-weight: 700; font-size: 13px; color: #f87171; letter-spacing: 0.01em;'>
                                            PERINGATAN: Cabang Memiliki Data Aktif!
                                        </div>
                                        <div style='font-size: 11.5px; color: #9ca3af; margin-top: 1px;'>
                                            Data operasional berikut terdaftar pada cabang ini:
                                        </div>
                                    </div>
                                </div>

                                <div style='display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 6px; margin-bottom: 12px;'>
                                    {$gridHtml}
                                </div>

                                <div style='display: flex; align-items: center; gap: 6px; font-size: 11.5px; color: #f87171; border-top: 1px solid rgba(239, 68, 68, 0.18); padding-top: 9px; line-height: 1.4;'>
                                    <span>•</span>
                                    <span>Seluruh data operasional di atas akan <strong>dihapus permanen</strong> dan tidak dapat dipulihkan!</span>
                                </div>
                            </div>

                            <p style='color: #9ca3af; font-size: 12px; line-height: 1.45; margin: 0;'>
                                Ketik password akun login Anda di bawah ini untuk mengonfirmasi penghapusan permanen.
                            </p>
                        </div>
                    ");
                }

                return new \Illuminate\Support\HtmlString("
                    <div style='text-align: left; margin: 4px 0 12px 0;'>
                        <div style='background: rgba(255, 255, 255, 0.03); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 10px; padding: 12px 14px; margin-bottom: 10px; display: flex; align-items: center; gap: 8px;'>
                            <span style='color: #10b981; font-size: 15px;'>✓</span>
                            <span style='color: #9ca3af; font-size: 12.5px;'>Cabang ini belum memiliki data riwayat transaksi atau produk.</span>
                        </div>
                        <p style='color: #9ca3af; font-size: 12px; line-height: 1.45; margin: 0;'>
                            Ketik password akun login Anda di bawah ini untuk mengonfirmasi penghapusan cabang.
                        </p>
                    </div>
                ");
            })
            ->modalSubmitActionLabel('Hapus Permanen')
            ->form([
                TextInput::make('password')
                    ->label('Password Akun Anda')
                    ->password()
                    ->revealable()
                    ->required()
                    ->placeholder('Masukkan password Anda saat ini')
                    ->helperText('Konfirmasi identitas dengan password akun login Anda.'),
            ])
            ->action(function (Branch $record, array $data, $livewire): void {
                $user = auth()->user();
                try {
                    $name = $record->name;
                    $record->safeDeleteWithPassword($data['password'], $user);
                    Notification::make()
                        ->success()
                        ->title('Cabang Berhasil Dihapus')
                        ->body("Cabang '{$name}' dan seluruh datanya telah berhasil dihapus permanen.")
                        ->send();

                    if (isset($livewire) && method_exists($livewire, 'redirect')) {
                        if ($livewire instanceof \Filament\Resources\Pages\EditRecord) {
                            $livewire->redirect(BranchResource::getUrl('index'));
                        }
                    }
                } catch (\Illuminate\Validation\ValidationException $e) {
                    Notification::make()
                        ->danger()
                        ->title('Password Salah!')
                        ->body('Password akun yang Anda masukkan salah. Penghapusan cabang dibatalkan demi keamanan.')
                        ->send();
                } catch (\Exception $e) {
                    Notification::make()
                        ->danger()
                        ->title('Gagal Menghapus Cabang')
                        ->body($e->getMessage())
                        ->send();
                }
            })
            ->visible(fn (Branch $record) => Branch::count() > 1);
    }

    public static function getRelations(): array
    {
        return [];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListBranches::route('/'),
            'create' => Pages\CreateBranch::route('/create'),
            'edit' => Pages\EditBranch::route('/{record}/edit'),
        ];
    }
}
