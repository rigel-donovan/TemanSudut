<x-filament-panels::page>
    <div class="space-y-6">
        <x-filament::section>
            <x-slot name="heading">Pengaturan Hak Akses per Role</x-slot>
            <x-slot name="description">
                Aktifkan atau nonaktifkan fitur-fitur aplikasi untuk setiap role karyawan. Perubahan akan langsung berlaku setelah disimpan.
            </x-slot>

            <div class="overflow-x-auto rounded-xl border border-gray-200 dark:border-white/10">
                <table class="w-full text-sm text-left">
                    <thead class="bg-gray-50 dark:bg-white/5">
                        <tr>
                            <th class="px-4 py-3 font-medium text-gray-950 dark:text-white" style="width: 50%;">
                                Fitur / Akses
                            </th>
                            <th class="px-4 py-3 font-medium text-amber-600 dark:text-amber-400 text-center" style="width: 25%;">
                                <div class="flex items-center justify-center gap-2">
                                    <x-filament::icon icon="heroicon-o-check-badge" class="w-5 h-5" />
                                    Owner
                                </div>
                            </th>
                            <th class="px-4 py-3 font-medium text-emerald-600 dark:text-emerald-400 text-center" style="width: 25%;">
                                <div class="flex items-center justify-center gap-2">
                                    <x-filament::icon icon="heroicon-o-user" class="w-5 h-5" />
                                    Kasir
                                </div>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-white/10">
                        @php
                            $featureList = [];
                            foreach (\Database\Seeders\RolePermissionSeeder::$features as $key => $config) {
                                $featureList[$key] = $config['label'];
                            }
                        @endphp

                        @foreach ($featureList as $key => $label)
                            <tr class="hover:bg-gray-50 dark:hover:bg-white/5 transition duration-75">
                                <td class="px-4 py-3 font-medium text-gray-950 dark:text-white">
                                    {{ $label }}
                                </td>

                                {{-- Owner Checkbox --}}
                                <td class="px-4 py-3 text-center">
                                    <label class="flex items-center justify-center cursor-pointer">
                                        <input 
                                            type="checkbox" 
                                            wire:model.live="permissions.{{ $key }}.owner"
                                            class="w-5 h-5 text-amber-600 rounded border-gray-300 focus:ring-amber-600 dark:border-gray-600 dark:bg-gray-700 dark:ring-offset-gray-800 focus:ring-2"
                                        >
                                    </label>
                                </td>

                                {{-- Kasir Checkbox --}}
                                <td class="px-4 py-3 text-center">
                                    <label class="flex items-center justify-center cursor-pointer">
                                        <input 
                                            type="checkbox" 
                                            wire:model.live="permissions.{{ $key }}.cashier"
                                            class="w-5 h-5 text-emerald-600 rounded border-gray-300 focus:ring-emerald-600 dark:border-gray-600 dark:bg-gray-700 dark:ring-offset-gray-800 focus:ring-2"
                                        >
                                    </label>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <div class="mt-4 flex justify-end">
                <x-filament::button wire:click="save" color="primary" size="md">
                    Simpan Perubahan
                </x-filament::button>
            </div>
        </x-filament::section>

    </div>
</x-filament-panels::page>
