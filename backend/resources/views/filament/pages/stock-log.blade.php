<x-filament-panels::page>
    <div class="mb-4">
        <x-filament::button
            tag="a"
            href="{{ \App\Filament\Pages\StockManagementPage::getUrl() }}"
            color="gray"
            icon="heroicon-o-arrow-left"
        >
            Kembali ke Stock Management
        </x-filament::button>
    </div>

    {{ $this->table }}
</x-filament-panels::page>
