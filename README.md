# Panduan Running

Dokumen ini adalah panduan untuk menyambungkan Komputer Anda (sebagai Server Utama) dengan Tablet Kasir **menggunakan Jaringan (LocalTunnel)**
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
Karena kita sudah menggunakan sistem kelas Enterprise (Tailscale), Anda **tidak perlu lagi membuka terminal Ngrok/LocalTunnel**.
Pastikan saja aplikasi Tailscale di Komputer dan di Tablet Kasir sama-sama sudah ter-install dan dalam kondisi **Connected/Active**!

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
