<x-filament-panels::page>
    <div class="space-y-6">
        {{-- Header Card --}}
        <div class="fi-section rounded-xl bg-white shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
            <div class="fi-section-content p-6">
                <div class="flex items-center gap-4 mb-6">
                    <div class="flex flex-shrink-0 h-14 w-14 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/30">
                        <x-heroicon-o-circle-stack class="text-amber-600 dark:text-amber-400" style="width: 32px; height: 32px; flex-shrink: 0;" />
                    </div>
                    <div>
                        <h2 class="text-xl font-bold text-gray-900 dark:text-white">Backup Database</h2>
                        <p class="text-sm text-gray-500 dark:text-gray-400">Unduh salinan keamanan seluruh data kasir</p>
                    </div>
                </div>

                {{-- Info cards --}}
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                    <div class="rounded-lg bg-blue-50 dark:bg-blue-900/20 p-4 border border-blue-100 dark:border-blue-800">
                        <div class="flex items-center gap-2 mb-1">
                            <x-heroicon-m-document-text class="text-blue-600" style="width: 16px; height: 16px; flex-shrink: 0;" />
                            <span class="text-xs font-semibold text-blue-700 dark:text-blue-400 uppercase tracking-wide">Format</span>
                        </div>
                        <p class="text-sm font-medium text-blue-900 dark:text-blue-200">SQLite (.sqlite)</p>
                    </div>

                    <div class="rounded-lg bg-green-50 dark:bg-green-900/20 p-4 border border-green-100 dark:border-green-800">
                        <div class="flex items-center gap-2 mb-1">
                            <x-heroicon-m-check-circle class="text-green-600" style="width: 16px; height: 16px; flex-shrink: 0;" />
                            <span class="text-xs font-semibold text-green-700 dark:text-green-400 uppercase tracking-wide">Isi Backup</span>
                        </div>
                        <p class="text-sm font-medium text-green-900 dark:text-green-200">Semua data tersimpan</p>
                    </div>

                    <div class="rounded-lg bg-amber-50 dark:bg-amber-900/20 p-4 border border-amber-100 dark:border-amber-800">
                        <div class="flex items-center gap-2 mb-1">
                            <x-heroicon-m-clock class="text-amber-600" style="width: 16px; height: 16px; flex-shrink: 0;" />
                            <span class="text-xs font-semibold text-amber-700 dark:text-amber-400 uppercase tracking-wide">Terakhir Backup</span>
                        </div>
                        <p class="text-sm font-medium text-amber-900 dark:text-amber-200" id="last-backup-text">Belum ada catatan</p>
                    </div>
                </div>

                {{-- Download Button --}}
                <div class="flex flex-col sm:flex-row items-start sm:items-center gap-4">
                    <button
                        id="backup-download-btn"
                        type="button"
                        onclick="triggerBackupDownload()"
                        class="inline-flex items-center gap-2 rounded-lg bg-amber-600 px-6 py-3 text-sm font-semibold text-white shadow-sm hover:bg-amber-500 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2 transition-all duration-200 active:scale-95">
                        <x-heroicon-m-arrow-down-tray style="width: 20px; height: 20px; flex-shrink: 0;" />
                        Download Backup Sekarang
                    </button>
                </div>
            </div>
        </div>

    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            const lastBackup = localStorage.getItem('kasir_last_backup');
            const el = document.getElementById('last-backup-text');
            if (lastBackup && el) {
                const d = new Date(parseInt(lastBackup));
                el.textContent = d.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
            }
        });

        function triggerBackupDownload() {
            recordBackupTime();
            window.location.href = '{{ route('admin.backup.download') }}';
        }

        function recordBackupTime() {
            localStorage.setItem('kasir_last_backup', Date.now().toString());
            localStorage.setItem('kasir_backup_reminder_dismissed', Date.now().toString());
        }

        function resetBackupReminder() {
            localStorage.removeItem('kasir_backup_reminder_dismissed');
            showBackupReminderPopup();
        }
    </script>
</x-filament-panels::page>
