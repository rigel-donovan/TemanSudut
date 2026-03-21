# Panduan Mudah Menjalankan Aplikasi Kasir di Toko

Dokumen ini adalah panduan untuk menyambungkan Komputer Anda (sebagai Server) dengan Tablet/HP Kasir **menggunakan Jaringan Publik / Tunneling (Cloudflare / Ngrok)**, sehingga Kasir dan Bos bisa mengakses dari mana saja tanpa peduli jaringan Wi-Fi yang digunakan.

---

## TAHAP 1: Menghidupkan Backend di Komputer
Komputer Anda wajib menyala terus selama toko buka.
1. Buka layar hitam pencarian (Terminal / CMD) di dalam folder `backend` aplikasi Anda.
2. Nyalakan mesin pencatat datanya dengan mengetikkan persis perintah ini:
   ```bash
   php artisan serve --host=0.0.0.0 --port=8000
   ```
   *(Biarkan layar hitam ini terus menyala dan jangan di-close selama aplikasi kasir masih dipakai).*

---

## TAHAP 2: Membuat "Jalan Tol" (Tunnel) ke Internet
Agar Tablet/HP Anda (yang menggunakan jaringan berbeda) bisa masuk ke PC Anda, kita butuh membuat "Tunnel" publik.
1. Buka Terminal (CMD/PowerShell) baru di folder utama proyek Anda.
2. Ketikkan perintah ini untuk membuat link `trycloudflare` baru:
   ```bash
   .\cloudflared.exe tunnel --url http://localhost:8000
   ```
3. Nanti di layar akan muncul sebuah link unik HTTPS (Misalnya: `https://proceed-substances-organ-tasks.trycloudflare.com`). **Salin link tersebut**.
   *(Sama seperti Tahap 1, layar hitam ini pantang di-close/dimatikan).*

---

## TAHAP 3: Membuat Aplikasi (.APK) untuk Tablet Kasir
Karena kita sudah punya link "Jalan Tol" di atas, sekarang kita atur Tablet Kasir agar memanggil link tersebut.
1. Buka file bernama `api_service.dart` di dalam folder `lib/services`.
2. Ubah baris `baseUrl` menjadi Link Cloudflare yang Anda dapat di Tahap 2, HANYA ditambahkan `/api` di ujungnya.
   Isinya akan terlihat seperti ini:
   ```dart
   static const String baseUrl = 'https://proceed-substances-organ-tasks.trycloudflare.com/api';
   // (Ganti dengan link Cloudflare terbaru Anda)
   ```
3. Buka Terminal baru di folder utama aplikasi Anda, lalu ketik ini untuk membuat file APK (bahan instalasi Android):
   ```bash
   flutter build apk
   ```
4. Tunggu sampai selesai. Nanti akan muncul file aplikasi bernama `app-release.apk`. Cari file tersebut di folder:  
   `d:\my projects\kasir-android\build\app\outputs\flutter-apk\`

---

## TAHAP 4: Mulai Berjualan!

**1. Untuk Kasir (Tablet / LDPlayer Emulator):**
- Pindahkan file `app-release.apk` tadi ke dalam Tablet Anda (bisa kirim via WhatsApp, Kabel, dll), lalu **Install**.
- Buka aplikasinya, login (contoh: `farisatsal@gmail.com`), dan Kasir siap melayani pembeli dari mana saja!

**2. Untuk Pemilik Toko (Admin / Bos):**
- Bos tidak perlu install aplikasi. Cukup gunakan HP, Tablet Pribadi, atau Komputer lain di jangkauan internet manapun.
- Buka Google Chrome / Safari, lalu masukkan Link Cloudflare (Tahap 2) dengan ambahan `/admin` di belakangnya.  
   Contohnya begini:  
   `https://proceed-substances-organ-tasks.trycloudflare.com/admin`
- Masukkan Email dan Password Bos, lalu Anda bisa memantau penjualan harian!

---

## 💡 CATATAN PENTING:
Jika komputer Anda dimatikan atau direstart, Link Cloudflare di Tahap 2 akan **mati dan berubah menjadi link acak yang baru** jika Anda menjalankannya lagi.
Jika itu terjadi, Anda wajib mengulangi Tahap 3 (mengganti link di kode & membikin APK baru) agar Tablet kembali terhubung.
