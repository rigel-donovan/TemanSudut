<div id="backup-reminder-overlay"
    style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.5); z-index:9999; align-items:center; justify-content:center;">
    <div style="background:#fff; border-radius:16px; padding:32px; max-width:420px; width:90%; box-shadow:0 20px 60px rgba(0,0,0,0.3); position:relative;">
        {{-- Dark mode support --}}
        <style>
            @media (prefers-color-scheme: dark) {
                #backup-reminder-overlay > div { background: #1f2937 !important; }
                #backup-reminder-title { color: #f9fafb !important; }
                #backup-reminder-desc { color: #9ca3af !important; }
            }
            .filament-dark #backup-reminder-overlay > div { background: #1f2937 !important; }
            .filament-dark #backup-reminder-title { color: #f9fafb !important; }
            .filament-dark #backup-reminder-desc { color: #9ca3af !important; }
        </style>

        {{-- Icon --}}
        <div style="display:flex; justify-content:center; margin-bottom:16px;">
            <div style="background:#fef3c7; border-radius:50%; width:64px; height:64px; display:flex; align-items:center; justify-content:center;">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="#d97706" width="32" height="32">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M20.25 6.375c0 2.278-3.694 4.125-8.25 4.125S3.75 8.653 3.75 6.375m16.5 0c0-2.278-3.694-4.125-8.25-4.125S3.75 4.097 3.75 6.375m16.5 0v11.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125V6.375m16.5 2.25c0 2.278-3.694 4.125-8.25 4.125s-8.25-1.847-8.25-4.125" />
                </svg>
            </div>
        </div>

        {{-- Content --}}
        <h3 id="backup-reminder-title" style="font-size:1.125rem; font-weight:700; color:#111827; text-align:center; margin:0 0 8px;">
            Backup Data!
        </h3>
        <p id="backup-reminder-desc" style="font-size:0.875rem; color:#6b7280; text-align:center; line-height:1.5; margin:0 0 24px;">
            Sudah 7 hari belum backup data kasir Anda.
        </p>

        {{-- Buttons --}}
        <div style="display:flex; flex-direction:column; gap:10px;">
            <a href="{{ route('admin.backup.download') }}"
                onclick="dismissBackupReminderWithBackup(); return true;"
                style="display:flex; align-items:center; justify-content:center; gap:8px; background:#d97706; color:#fff; border-radius:8px; padding:12px 20px; font-size:0.875rem; font-weight:600; text-decoration:none; transition:background 0.2s;"
                onmouseover="this.style.background='#b45309'" onmouseout="this.style.background='#d97706'">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" width="16" height="16">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" />
                </svg>
                Backup Sekarang
            </a>
            <button onclick="dismissBackupReminder()"
                style="background:transparent; border:1px solid #d1d5db; border-radius:8px; padding:10px 20px; font-size:0.875rem; color:#6b7280; cursor:pointer; transition:background 0.2s;"
                onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                Ingatkan Lagi Minggu Depan
            </button>
        </div>
    </div>
</div>

<script>
    const REMINDER_KEY = 'kasir_backup_reminder_dismissed';
    const BACKUP_KEY = 'kasir_last_backup';
    const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

    function showBackupReminderPopup() {
        const el = document.getElementById('backup-reminder-overlay');
        if (el) el.style.display = 'flex';
    }

    function dismissBackupReminder() {
        localStorage.setItem(REMINDER_KEY, Date.now().toString());
        const el = document.getElementById('backup-reminder-overlay');
        if (el) el.style.display = 'none';
    }

    function dismissBackupReminderWithBackup() {
        localStorage.setItem(REMINDER_KEY, Date.now().toString());
        localStorage.setItem(BACKUP_KEY, Date.now().toString());
        const el = document.getElementById('backup-reminder-overlay');
        if (el) el.style.display = 'none';
    }

    document.addEventListener('DOMContentLoaded', function () {
        const lastDismissed = localStorage.getItem(REMINDER_KEY);
        const now = Date.now();

        const shouldShow = !lastDismissed || (now - parseInt(lastDismissed)) > SEVEN_DAYS_MS;

        if (shouldShow) {
            setTimeout(showBackupReminderPopup, 1500);
        }
    });
</script>
