# Pengujian Infinix, 6 November 2026

Penguji teknis adalah agen melalui ADB pada perangkat asli. UAT pengguna nyata
berstatus NOT RUN karena belum ada penguji yang menyatakan siap.

## Perangkat dan build

Infinix X6833B, Android 14/API 34, 1080×2460, density 480, RAM terlapor
7.869.764 kB. Font awal 1.0, diuji pada 1.3 lalu dikembalikan ke 1.0.
Sesi pagi sekitar 09.45–10.15 WIB dan lanjutan sekitar 14.45 WIB.
HEAD awal be48f3312ebe28b82600cc6682fae5398b729bfa. Build perbaikan yang
digunakan untuk hasil di bawah berasal dari 316b6ab36d28cd1a88baa25340f1dac8973383e8.
APK debug emulator berukuran 216243865 byte, SHA256
93D76E7CEAF4808FEAAAF8AC56D1DFD4FDCD6C64B88F248089ACA7091D361DF1.
Penyuntingan kalimat sesudah sesi ini dicatat terpisah pada commit berikutnya.

Project demo-bengkelku. Auth 127.0.0.1:9099 dan Firestore 127.0.0.1:8080.
Kedua adb reverse diverifikasi sebelum login, lalu dipasang ulang setelah jeda.
Seed dan validasi PASS, empat akun, lima layanan dan 115 dokumen domain.
Ringkasan awal tersedia pada [bukti seed](evidence/phase07-20261106/seed-validation.json).
Percobaan startup kedua saat lanjutan gagal karena port sudah terpakai.
Instance yang telah berjalan digunakan setelah validasi ulang PASS.

## Bug yang direproduksi

QA-11. SDK mengubah host loopback menjadi 10.0.2.2 pada Android fisik.
Log perangkat menunjukkan pemetaan Auth dan Firestore. Kedua pemetaan otomatis
dinonaktifkan pada 9ffb1ec. Test routing gagal sebelum perbaikan dan PASS sesudahnya.

QA-12. Login berikutnya ditolak Android dengan pesan Cleartext HTTP traffic to
127.0.0.1 not permitted. Konfigurasi debug pada 316b6ab mengizinkan HTTP untuk
127.0.0.1, localhost dan 10.0.2.2. Test memastikan opt-in berada pada debug saja.
Test sebelum perbaikan gagal, sesudah perbaikan 2/2 PASS. Login tiga role
berhasil setelah kedua perbaikan.

QA-13. Pengguna melaporkan dropdown Jenis layanan ditekan tanpa membuka daftar.
Pada build emulator di atas, tap membuka Ganti Oli, Servis Rem, Tune Up,
Servis Berkala dan Pemeriksaan Kelistrikan. Ganti Oli dapat dipilih dan booking
berhasil dikirim. Gejala belum tereproduksi pada lingkungan ini. Kondisi katalog
dan build saat laporan awal belum terverifikasi. Temuan tetap terbuka untuk triase.

## Hasil AND-01 sampai AND-11

| ID | Status | Actual dan batas pengujian |
| --- | --- | --- |
| AND-01 | PASS | Tiga force-stop/cold start menampilkan dashboard teknisi dan mempertahankan sesi. Waktu am start 3559, 3382 dan 3252 ms |
| AND-02 | PASS | Login/logout pelanggan, admin dan teknisi mengarahkan ke dashboard role masing-masing |
| AND-03 | NOT RUN | Bagian yang selesai: pilih kendaraan existing, layanan, tanggal/jam, kirim booking dan cancel berhasil. CRUD kendaraan serta rebooking slot belum diuji pada sesi ini |
| AND-04 | NOT RUN | Bagian yang selesai: teknisi membuka SO sendiri dan menyimpan tiga checklist, diagnosis serta tindakan. Confirm/SO/assignment admin belum dijalankan di UI |
| AND-05 | NOT RUN | Inventori, ledger, pemakaian SO dan form request terbaca. Request/approval/retry belum dieksekusi di perangkat |
| AND-06 | NOT RUN | Daftar invoice dan laporan terbuka, 9 booking/4 completed/omzet fixture Rp127.000. Mutasi invoice/payment di perangkat belum dijalankan |
| AND-07 | NOT RUN | Native PDF print/share belum dieksekusi |
| AND-08 | PASS | Home/foreground dan tiga process-kill/cold start mempertahankan sesi teknisi. Tidak ada submit transaksi saat lifecycle diuji |
| AND-09 | NOT RUN | Keyboard dan Back dipakai saat login/input, dashboard font 1.3 terbaca. Rotasi dan font terbesar belum diuji |
| AND-10 | NOT RUN | Kehilangan reverse setelah jeda teramati dan dipulihkan. Putus koneksi saat submit belum diuji |
| AND-11 | PASS | Log proses terakhir tidak memuat FATAL EXCEPTION, Unhandled Exception atau RenderFlex overflow. Batas bukti adalah jendela log proses yang diperiksa |

NOT RUN pada alur yang baru diuji sebagian tetap memerlukan pelaksanaan sisa
langkah. Status tersebut tidak berarti seluruh fitur pada baris gagal.

## Bukti dan tindak lanjut

Screenshot berasal dari screencap Infinix, menggunakan data emulator. Nama file
dan hash dicatat pada manifest bukti. Gambar sebelum penyuntingan kalimat
mempertahankan teks yang terlihat saat pengujian.

[Manifest bukti](evidence/phase07-20261106/manifest.json) memuat screenshot,
ringkasan seed dan test red/green. Bukti login/admin, pilihan layanan, kirim/cancel,
laporan, checklist, cold start dan font disimpan pada direktori yang sama.

## Penyuntingan kalimat

Antislop During dipilih pengguna. Lima teks diperbaiki di source dashboard dan
pembayaran. Slogan seperti “jaga bengkel tetap bergerak” diganti dengan
“Kelola booking dan pekerjaan bengkel”. Label laporan menjadi “Muat laporan”.
Test widget existing yang relevan PASS 34/34 setelah penyuntingan.

Gate copy pada cakupan perubahan ini PASS untuk R-02/R-15/R-16/R-36.
Kalimat menyebut tindakan yang tersedia, label tombol sesuai aksi, dan tidak
menambah statistik atau klaim produk. Pemeriksaan bentuk tulisan PASS, lima
teks baru tidak memakai em dash atau slogan. Gate seluruh aplikasi tetap
mengikuti QA_GATE karena kasus perangkat dan UAT masih tersisa.

Selesaikan AND-03..07, AND-09..10 dan kasus black-box yang tersisa. Fasilitator
menyiapkan akun per role dan mencatat actual UAT sebelum meminta penilaian.
Form responden, skor dan persetujuan tetap kosong. Gate masih BLOCKED.

QA-01 diterima sebagai batas scope Phase 07 berdasarkan keputusan yang
didelegasikan pengguna. Operator mengelola katalog melalui Console. UI CRUD
katalog untuk TA memerlukan instruksi implementasi terpisah.

Rules production telah dirilis pada sesi sebelumnya dengan instruksi eksplisit
pengguna dan konfirmasi Deploy complete. Indexes belum dideploy pada sesi itu.
Penutupan ini memakai emulator dan tidak menjalankan deploy production.
