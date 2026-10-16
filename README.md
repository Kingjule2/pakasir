# Pakasir2 — React mobile + Laravel

Frontend aktif: **`mobile/` (React JS + Vite)**, untuk browser ponsel dan desktop; bukan React Native atau APK. Backend tetap Laravel di `backend/`. Berkas Flutter pengguna (`lib/`, `android/`, `web/`, dan lainnya) dipertahankan sebagai sumber referensi, tidak ditimpa.

Sumber telah di-clone ke `../pakasir-upstream` dari https://github.com/Kingjule2/pakasir, revisi `364a2e168333d1d200b65121aa8e26ca7abf0216`. Clone referensi terpisah agar pekerjaan lokal yang belum berada dalam Git tidak hilang. Pembaruan upstream berikutnya perlu ditinjau dan dipindahkan ke React; `git pull` tidak mengonversi perubahan Dart secara otomatis.

## Menjalankan

Prasyarat: Node.js 22+, Composer, PHP **8.4.1+** untuk dependency lock/vendor saat ini (meskipun composer.json menuliskan ^8.3), ekstensi PDO SQLite, mbstring, OpenSSL, cURL, fileinfo, DOM/XML. SQLite tersedia untuk lokal; driver/database PostgreSQL perlu dikonfigurasi untuk deployment PostgreSQL.

Backend, terminal pertama:

```powershell
cd pakasir2/backend
# Instal dependency jika vendor belum tersedia:
composer install
# Hanya untuk instalasi baru tanpa .env:
# Copy-Item .env.example .env
# php artisan key:generate
php artisan migrate
# Hanya pada database baru/kosong untuk data contoh lokal:
# php artisan db:seed
php artisan serve --host=127.0.0.1 --port=8001
```

PHP default workstation ini masih 8.1. Runtime portabel yang dipakai untuk verifikasi adalah `D:/php-pakasir-8.5/php.exe`; gunakan path tersebut menggantikan `php`, atau atur PATH ke PHP yang kompatibel. Jangan menonaktifkan pengecekan versi Composer.

Frontend, terminal kedua:

```powershell
cd pakasir2/mobile
npm ci
npm run dev
```

Buka `http://127.0.0.1:5173`. Proxy Vite meneruskan `/api` ke `http://127.0.0.1:8001`. Akun **data contoh lokal**: `admin@vault-retail.id` / `password123`. Jangan gunakan akun/token seeder untuk produksi.

Build frontend: `npm run build` di `mobile/`; hasil di `mobile/dist`. Pada deployment, layani frontend dan `/api` di origin HTTPS yang sama melalui reverse proxy. Vite proxy hanya untuk development. Jangan memuat credential gateway/model dalam variabel frontend `VITE_*`.

## Fitur dan konsistensi data

- React mengikuti identitas Vault/Pakasir: sidebar gelap, aksen lime, kartu operasional, navigasi khusus layar kecil.
- Dashboard, inventory, kasir, penerimaan stok, pelanggan, outlet, laporan, bantuan, pengaturan, privasi, Supri, dan langganan memakai API Laravel, bukan penyimpanan data palsu di browser.
- Dashboard dan laporan memakai transaksi POS `paid`. Pendapatan mengecualikan pajak; HPP memakai biaya item saat checkout. Laba bersih, biaya operasional, dan saldo kas yang belum dicatat ditandai tidak tersedia, bukan diberi angka contoh.
- CSV laporan merupakan unduhan nyata dengan filter Hari Ini/Minggu Ini/Bulan Ini/Tahun Ini. Ekspor data toko menghasilkan JSON produk, pelanggan, outlet, transaksi, dan pengaturan; **bukan backup SQL terenkripsi**, dan mengandung data pelanggan.
- Kasir menolak pembelian melebihi stok, membatalkan seluruh perubahan bila salah satu item gagal, dan menghitung pajak/biaya layanan dari pengaturan server. Metode QRIS/EDC di kasir adalah pencatatan pembayaran oleh operator, **bukan konfirmasi gateway otomatis**.
- Penerimaan stok tidak berpura-pura melakukan pemesanan atau menghubungi pemasok.
- Preferensi MFA/biometrik/anonimisasi lama hanya catatan pengaturan. UI/API tidak mengklaim kontrol itu sudah diterapkan atau aplikasi sudah tersertifikasi kepatuhan.

## Paket sementara

| Paket | Harga per bulan | SKU | Akun aktif | Prompt Supri |
|---|---:|---:|---:|---:|
| Basic | Rp99.000 | 200 | 1 | 50 |
| Pro / Juragan | Rp299.000 | 2.000 | 3 | 2.000 |
| Enterprise | mulai Rp999.000 | tanpa batas SKU | tanpa batas akun | anggaran sesuai kontrak |

Sumber harga/limit berada di `backend/config/billing.php`; frontend mengambilnya dari API. Batas prompt berlaku untuk **seluruh toko dalam satu periode langganan**, bukan 2.000 untuk setiap staf. Seat owner diprioritaskan, kemudian staf berdasarkan ID. Akun tidak dihapus ketika melewati batas paket; akses operasionalnya ditolak selama paket terbatas aktif.

Enterprise melalui permintaan penawaran. SOP dapat dipasang sebagai system context pada kontrak Enterprise, bukan fine-tuning model. Laporan kustom dan integrasi POS eksternal adalah kebutuhan kontrak yang perlu disepakati; tidak ada integrasi ke penyedia POS tertentu yang diklaim sudah tersedia.

## Pembayaran langganan

Implementasi menggunakan **Midtrans Snap hosted checkout**. Atur `.env` backend:

```dotenv
MIDTRANS_SERVER_KEY=
MIDTRANS_IS_PRODUCTION=false
BILLING_OWNER_ID=
BILLING_ENTERPRISE_CONTACT=
```

- Gunakan server key sandbox untuk pengujian; produksi memerlukan akun merchant, server key produksi, dan HTTPS.
- Atur Payment Notification URL di dashboard Midtrans ke `https://domain-anda/api/billing/webhook` (bukan localhost).
- `BILLING_OWNER_ID` opsional; default superadmin pertama. Contact Enterprise opsional; jika kosong, gunakan tiket bantuan.
- Checkout hanya untuk owner, nominal ditentukan server, idempotency key mencegah duplikasi. Invoice yang belum selesai dipakai kembali.
- Aktivasi hanya setelah signature notifikasi valid **dan** status order/nominal dikonfirmasi melalui API server Midtrans. Redirect browser tidak pernah mengaktifkan paket.
- Paket prabayar berlaku satu bulan kalender sejak aktivasi. Tidak ada debit otomatis, prorata, atau perubahan paket di tengah periode; pembelian berikutnya setelah periode berakhir.
- Notifikasi duplikat tidak memperpanjang periode. Refund/chargeback menangguhkan entitlement terkait.
- Tanpa server key, tombol checkout menjelaskan konfigurasi yang belum tersedia dan backend mengembalikan 503; tidak ada pembayaran sukses simulasi.
- Timeout checkout yang ambigu dipertahankan sebagai `creating`. Jangan menghapus invoice atau membuat pembayaran manual baru tanpa rekonsiliasi dashboard gateway; order mungkin sudah dibuat.

Referensi protokol: https://docs.midtrans.com/docs/https-notification-webhooks

API utama: `GET /api/billing/plans`, `GET /api/billing/subscription`, `GET /api/billing/invoices`, `POST /api/billing/checkout`, `GET /api/billing/invoices/{id}`, `POST /api/billing/webhook`. Selain plans/webhook/login/health, API bisnis memerlukan Bearer token. Logout mencabut token.

## Supri, AIBrain, dan pengendalian biaya

**AIBrain dipakai sebagai konteks/skill pengembangan**, bukan API inferensi pelanggan. Project AIBrain: `proj-a69e54e0`; packet: `packet-7de9a233-5c66-4ea9-97f0-c00a3d353946`. Skill Frontend Design dipakai untuk token visual, responsivitas, state komponen, dan aksesibilitas. Workspace AIBrain lokal tidak perlu diekspos atau dijalankan agar aplikasi Pakasir bekerja.

Provider model existing yang didukung adalah Gemini. Atur backend:

```dotenv
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
ENTERPRISE_SOP=
```

Kode Flutter referensi di `lib/` tidak menyimpan API key dalam source. Untuk pengujian lokal saja, `GeminiService.apiKey` membaca konfigurasi build `GEMINI_API_KEY` melalui `--dart-define`; tanpa konfigurasi nilainya kosong. Nilai `--dart-define` tetap dapat diekstrak dari aplikasi hasil build, sehingga bukan penyimpanan secret yang aman untuk distribusi. Frontend React aktif tetap menggunakan backend Laravel; key produksi hanya boleh berada di environment backend. Cabut/rotasi key yang sebelumnya pernah hardcoded, dan jangan meng-commit key penggantinya.

Antigravity disebut pada asumsi biaya awal, tetapi belum ada kontrak endpoint/model/kredensial untuk integrasi itu. Tidak ada endpoint Antigravity rekaan. Harga token simulator adalah **input estimasi pengguna**, bukan kutipan tarif Gemini atau Antigravity.

- Permintaan Supri memerlukan paket aktif dan reservasi kuota atomik; paket tidak aktif/kedaluwarsa → 402, kuota habis → 429.
- Provider hilang/gagal → 503, kuota dikembalikan, tidak ada jawaban keuangan fiktif sebagai fallback.
- Batas pesan 4.000 byte, riwayat maksimal enam pesan × 1.000 byte, konteks bisnis/memori/SOP dibatasi, output maksimal 1.024 token. Batas prompt **bukan plafon tagihan rupiah**; system prompt, riwayat, dan output tetap menghabiskan token.
- Catatan Supri adalah konteks toko yang disimpan owner, bukan pelatihan model. Enterprise membutuhkan `prompt_limit` yang disepakati pada provisioning kontrak sebelum dapat memakai AI.
- Jika proses server mati setelah reservasi, reservasi dapat tetap terhitung; operator perlu rekonsiliasi penggunaan. Jangan mereset penggunaan otomatis tanpa bukti.

Simulator HPP mengalokasikan `(VPS + database) / jumlah pelanggan berbayar` lalu menambahkan biaya API per pelanggan. Masukkan **total token input + konteks + riwayat + output** per pertanyaan. Asumsi 30 pertanyaan/hari × 30 hari × 500–1.000 token menghasilkan 450.000–900.000 token/bulan, sebelum tambahan konteks yang belum termasuk asumsi. VPS Rp150–300 ribu dan database Rp0 jika cohost atau sekitar Rp200 ribu merupakan estimasi awal, bukan biaya yang ditagih aplikasi. Kontribusi harga dikurangi HPP bukan laba bersih: belum memasukkan payment fee, pajak, dukungan, backup, maupun biaya tenaga kerja.

## Verifikasi

```powershell
cd pakasir2/backend
php artisan test
cd ../mobile
npm run build
```

Backend: 33 tes / 164 assertion lulus pada PHP 8.5.11, mencakup signature/nominal/status gateway, kepemilikan invoice, aktivasi idempotent, batas kuota/SKU/seat, rollback checkout, periode laporan, serta ekspor data. HTTP smoke memakai database SQLite terisolasi: 401 tanpa autentikasi, 503 gateway belum dikonfigurasi, 402 AI tanpa paket, 503 AI tanpa key dengan kuota tetap nol, penolakan oversell 422, dan CSV/JSON unduhan nyata. Pengujian gateway otomatis memakai respons provider terkontrol; **bukan bukti pembayaran merchant atau respons model live**.

Frontend: build produksi Vite berhasil. Browser Chromium diperiksa pada viewport mobile 390 × 844, pricing 360 × 800, dan desktop 1440 × 1000. Alur yang dijalankan: login; seluruh menu operasional; tambah produk dan persistensi setelah reload; restock; kasir Tunai/EDC dengan pengurangan stok; perubahan pajak tersimpan dan dipakai checkout berikutnya; unduh CSV; kalkulator HPP termasuk input tidak valid; penyimpanan catatan Supri; serta konsultasi Enterprise yang muncul sebagai tiket bantuan. Sidebar tersembunyi tidak menerima fokus, tombol Supri memiliki label mobile, dan hanya paket yang dipilih ditandai berjalan.

Setelah smoke, backend dikembalikan ke database utama: tetap 6 produk, 2 transaksi, dan 6 pelanggan; hanya migrasi tabel billing yang ditambahkan. Fixture langganan Pro dan transaksi pengujian tidak dimasukkan ke data utama. Cadangan sebelum migrasi lokal tersimpan di `D:/php-pakasir-8.5/pakasir-before-billing.sqlite`.

## Batas deployment

Arsitektur existing adalah **satu toko bersama per instalasi**, bukan SaaS multi-tenant. Riwayat Supri/data operasional dibagi dalam toko; billing hanya dapat dikelola owner. Jangan meng-host beberapa pelanggan perusahaan pada database ini seolah tenant mereka terisolasi. Sebelum produksi: ganti akun demo, sediakan HTTPS, backup database sesungguhnya, konfigurasi secret, serta tinjau izin operasional staf dan kontrol keamanan yang dibutuhkan bisnis.
