# Panduan Running

Dokumen ini adalah panduan untuk menyambungkan Komputer Anda (sebagai Server Utama) dengan Tablet Kasir
---

## TAHAP 1: Menghidupkan Induk Server di Komputer Utama
Komputer penyimpan database ini wajib menyala terus selama jam operasional toko.
1. Buka Terminal (Command Prompt / PowerShell) di dalam folder **`backend`** aplikasi Anda.
2. Nyalakan mesin server databasenya dengan mengetikkan perintah ini:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   *(Biarkan layar terminal ini terus menyala dan jangan pernah di-close selama jam kerja).*

---

## TAHAP 2: Membuka Penghubung (Tailscale VPN)
Karena kita sudah menggunakan sistem kelas Enterprise (Tailscale), Anda **tidak perlu lagi repot membuka terminal khusus**.
Pastikan saja aplikasi Tailscale di Komputer dan di Tablet Kasir sama-sama sudah ter-install dan selalu dalam kondisi **Connected/Active** selama jam toko!

---

## TAHAP 3: Buka Toko & Mulai Berjualan!

**1. Untuk Kasir (Tablet / LDPlayer Emulator Utama):**
- Buka saja aplikasi Android Kasir Teman Sudut.
- Login dengan akun kasir (contoh: `farisatsal@gmail.com`), dan Tablet Kasir siap melayani transaksi pembeli!

**2. Untuk Bos / Admin Toko:**
- Pastikan HP / Laptop Bos juga sudah di-install aplikasi Tailscale dan login dengan akun Google yang sama.
- Buka browser (Google Chrome / Safari) kesayangan Bos.
- Ketik Link Web Admin toko Anda:  
   `http://100.123.248.104:8000/admin`
- Masukkan Email dan Password Bos, lalu pantau penjualan secara real-time dari mana saja.

---

## PANDUAN PENGGANTIAN IP (Bila Ganti Laptop / Ganti Akun Tailscale)

Jika di masa depan Anda mengganti Laptop Utama atau login dengan akun Tailscale yang berbeda, maka Nomor IP `100.x.x.x` Anda pasti akan berubah. Ikuti 2 langkah super gampang ini untuk menyesuaikannya:

**1. Di Mesin Database (Laravel)**
- Buka file: `backend/.env`
- Ubah baris `APP_URL=http://100.123.248.104:8000` dengan IP Anda yang baru.
- **SANGAT PENTING:** Matikan terminal server PHP yang sedang nyala dengan menekan **`Ctrl + C`**.
- Bersihkan memori usang dengan ngetik: `php artisan optimize:clear`
- Nyalakan ulang servernya: `php artisan serve --host=0.0.0.0 --port=8000`

**2. Di Aplikasi Tablet Kasir Android (Flutter)**
- Buka file: `lib/services/api_service.dart`
- Scroll ke baris atas, ubah kode `http://100.123.248.104:8000/api` menjadi IP Anda yang baru.
- Buka terminal baru dan jalankan perintah sakti: `flutter build apk`
- Pindahkan file *APK* murni racikan baru tersebut ke Tablet dan Install.
- Selesai! Kasir langsung siap jualan kembali selamanya!

*(Catatan bonus: Jangan lupa ganti juga tulisan angka 100... di `README` ini dengan IP Anda yang baru agar tidak kebingungan kalau dibaca tahun depan ya!)*
