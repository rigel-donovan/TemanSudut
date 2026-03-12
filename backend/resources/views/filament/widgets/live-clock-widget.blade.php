<x-filament-widgets::widget>
    <x-filament::section compact>
        <div 
            x-data="{ 
                time: '--:--:--', 
                date: 'Loading...',
                tick() {
                    const now = new Date();
                    this.time = now.toLocaleTimeString('id-ID', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' });
                    this.date = now.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
                }
            }" 
            x-init="tick(); setInterval(() => tick(), 1000)"
            class="flex items-center gap-x-3"
        >

            <div class="flex-shrink-0 flex items-center justify-center h-10 w-10 rounded-full bg-amber-500/10 text-amber-500">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" style="width: 24px !important; height: 24px !important; min-width: 24px !important; min-height: 24px !important; display: block !important;">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
                </svg>
            </div>
            
            <div class="flex-1 min-w-0">
                <div x-text="time" class="text-xl font-bold tracking-tight text-gray-950 dark:text-white leading-none">
                    --:--:--
                </div>
                <div x-text="date" class="text-xs font-medium text-gray-500 dark:text-gray-400 mt-1 truncate">
                    Loading date...
                </div>
            </div>
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
