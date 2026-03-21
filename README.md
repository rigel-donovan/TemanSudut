# Panduan Running

Dokumen ini adalah panduan untuk menyambungkan Komputer Anda (sebagai Server Utama) dengan Tablet Kasir **menggunakan Jaringan (Ngrok)**
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

## TAHAP 2: Membuka Penghubung (Ngrok)
Agar Tablet Kasir dan HP Bos bisa mengakses komputer dari jarak jauh (hanya modal kuota/internet apa saja), kita harus membuka jalurnya.
1. Buka Terminal (PowerShell) **baru** di folder UTAMA proyek Anda.
2. Nyalakan Ngrok ke alamat permanen toko Anda dengan perintah ini:
   ```bash
   .\ngrok http --domain=tigerishly-nonconductive-davin.ngrok-free.dev 8000
   ```
3. Selesai! Biarkan layar ini terus menyala bersama dengan layar di Tahap 1.

---

## TAHAP 3: Buka Toko & Mulai Berjualan!

**1. Untuk Kasir (Tablet / LDPlayer Emulator Utama):**
- Buka saja aplikasi Android Kasir Teman Sudut.
- Login dengan akun kasir (contoh: `farisatsal@gmail.com`), dan Tablet Kasir siap melayani transaksi pembeli!

**2. Untuk Bos / Admin Toko:**
- Cukup buka browser (Google Chrome / Safari) di HP, Tablet Pribadi, PC Rumah, dll.
- Ketik Link Web Admin toko Anda:  
   `https://tigerishly-nonconductive-davin.ngrok-free.dev/admin`
- Masukkan Email dan Password Bos, lalu pantau penjualan secara real-time dari mana saja di seluruh dunia.
