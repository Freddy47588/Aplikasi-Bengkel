# Before / after visual fidelity

Splash terbaru: [render sesuai rasio referensi](splash-reference.png) dan
[render export native](splash-native.png), menggantikan splash off-white
di set after historis. Lihat [laporan splash](../../SPLASH_REFERENCE_REPORT.md).

Baseline: commit `f6658c7`, render fixture yang sudah ada pada repository.
After: render ulang widget Flutter setelah perbaikan. Kedua set memakai
390x740dp, text scaling 100%, raster 780x1480. Konten di bawah viewport dapat
di-scroll. Data fixture, bukan data production atau screenshot perangkat.
Tanggal fixture yang berasal dari waktu render dapat berbeda.

Sepuluh referensi asli telah dibaca pada pesan pengguna "nih". Kode R01-R10
dan urutan lampiran dicatat pada laporan. Before adalah implementasi lama,
bukan referensi mockup. Panel poster dan bingkai ponsel tidak masuk aplikasi.

| Kelompok | Before | After | Perubahan yang terlihat |
| --- | --- | --- | --- |
| 1 Auth | [Splash](before/fixture-alignment-splash.png), [Login](before/fixture-alignment-login.png), [Daftar](before/fixture-alignment-register.png) | [Splash](after/fixture-alignment-splash.png), [Login](after/fixture-alignment-login.png), [Daftar](after/fixture-alignment-register.png) | Kendaraan vector-like, spacing login lebih ringkas |
| 2 Akun | [Verifikasi](before/fixture-alignment-verification.png), [Profil](before/fixture-alignment-customer-profile.png) | [Verifikasi](after/fixture-alignment-verification.png), [Profil](after/fixture-alignment-customer-profile.png) | Wave tidak mengambil ruang kerja akun, border lebih tenang |
| 3 Pelanggan | [Beranda](before/fixture-alignment-customer-home.png), [Kendaraan](before/fixture-alignment-customer-vehicles.png) | [Beranda](after/fixture-alignment-customer-home.png), [Kendaraan](after/fixture-alignment-customer-vehicles.png) | Mobil/motor lebih konsisten; daftar kendaraan lebih tinggi di viewport |
| 4 Booking | [Form](before/fixture-alignment-customer-booking.png), [Daftar](before/fixture-alignment-customer-bookings.png) | [Form](after/fixture-alignment-customer-booking.png), [Daftar](after/fixture-alignment-customer-bookings.png) | Header padat, form dikelompokkan, daftar lebih cepat diakses |
| 5 Admin | [Dashboard](before/fixture-alignment-admin-home.png), [Booking](before/fixture-alignment-admin-bookings.png) | [Dashboard](after/fixture-alignment-admin-home.png), [Booking](after/fixture-alignment-admin-bookings.png) | Hero ringkas, antrean lebih awal, wave dilepas |
| 6 Teknisi / SO admin | [Teknisi](before/fixture-alignment-admin-technicians.png), [SO](before/fixture-alignment-admin-orders.png) | [Teknisi](after/fixture-alignment-admin-technicians.png), [SO](after/fixture-alignment-admin-orders.png) | Header SO ringkas dan border data netral |
| 7 Teknisi / tugas | [Dashboard](before/fixture-alignment-technician-home.png), [Tugas](before/fixture-alignment-technician-orders.png) | [Dashboard](after/fixture-alignment-technician-home.png), [Tugas](after/fixture-alignment-technician-orders.png) | Kartu pekerjaan aktif terlihat sebelum statistik |
| 8 Checklist / sparepart | [Checklist](before/fixture-alignment-checklist.png), [Permintaan](before/fixture-alignment-request-part.png) | [Checklist](after/fixture-alignment-checklist.png), [Permintaan](after/fixture-alignment-request-part.png) | Form lebih lega; header permintaan lebih kecil |
| 9 Inventori / stok | [Inventori](before/fixture-alignment-admin-inventory.png), [Transaksi](before/fixture-alignment-stock-operation.png) | [Inventori](after/fixture-alignment-admin-inventory.png), [Transaksi](after/fixture-alignment-stock-operation.png) | Filter masuk viewport lebih awal; ikon jenis transaksi |
| 10 Pembayaran | [Invoice](before/fixture-alignment-admin-invoices.png), [Detail](before/fixture-alignment-admin-invoices-completed.png) | [Invoice](after/fixture-alignment-admin-invoices.png), [Detail](after/fixture-alignment-admin-invoices-completed.png) | Daftar invoice lebih awal, ruang vertikal detail bertambah |

Total baseline 36 gambar, after 37. Tambahan
[reset berhasil](after/fixture-alignment-password-reset-sent.png) merekam
state sesudah mengirim email; [form reset](after/fixture-alignment-password-reset.png)
kini mempunyai email dan Kirim Tautan tersendiri. Ring hitam pada FAB kendaraan adalah
indikator fokus keyboard yang tertangkap fixture. Tidak menyembunyikan ring
fokus untuk mempercantik screenshot.

Perbandingan dengan referensi: ilustrasi daftar dipusatkan, duplikasi judul
dikurangi, daftar teknisi/inventori muncul lebih cepat melalui filter yang
bisa dibuka, dan kartu SO menampilkan teknisi. Wave dibatasi pada layar yang
memerlukan dekorasi; navigasi dan kontrol operasional existing dipertahankan.

Atas permintaan lanjutan, logo dibuat ulang menjadi gear sederhana dengan
wrench di dalamnya. [Preview launcher](launcher-preview.png) adalah simulasi
mask circle/rounded-square/squircle dan export legacy, bukan screenshot
perangkat. Seluruh after dirender ulang memakai logo terbaru.

Regenerasi after:

```sh
flutter test test/ui_ux_polish_test.dart --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=build/visual-fidelity/after --plain-name "mockup alignment: capture actual Flutter screens with test fixtures"
```

Salin output ke folder `after/` setelah pemeriksaan visual. Lihat
[laporan](../../UI_VISUAL_FIDELITY_REPORT.md) untuk gap dan batas validasi.
