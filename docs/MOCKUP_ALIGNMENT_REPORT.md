# Penyelarasan mockup BengkelKu

Tanggal: 4 November 2026. Branch `refactor/ui-mockup-alignment`, base
`dd833d8d2cd9604fe98cf51804b202813e5dffab` (main fork saat pekerjaan dimulai).
Pekerjaan dilakukan di worktree terpisah agar perubahan pengguna di checkout
asal tidak tersentuh. Scope berhenti pada penyempurnaan UI/UX Phase 06.5.

## Referensi dan cakupan

Sepuluh papan mockup yang dilampirkan pengguna dibaca sebagai referensi visual.
Tabel berikut memetakan tema layar pada papan tersebut ke implementasi; ini
bukan klaim kesamaan piksel atau salinan seluruh fitur yang digambarkan.

| Papan/tema referensi | Implementasi yang ditinjau dan diperbarui |
| --- | --- |
| 1. Splash dan identitas | `workshop_ui.dart`, native launcher/splash Android dan iOS |
| 2. Masuk, daftar, reset, verifikasi | `login_screen.dart`, `foundation_pages.dart` |
| 3. Dashboard pelanggan dan kendaraan | `live_dashboard.dart`, `vehicles_screen.dart` |
| 4. Booking dan tracking | `customer_booking_screen.dart`, `foundation_pages.dart`, `service_timeline.dart` |
| 5. Dashboard admin dan booking | `live_dashboard.dart`, `foundation_pages.dart` |
| 6. Teknisi dan penugasan | `technicians_screen.dart`, `service_orders_screen.dart` |
| 7. Dashboard teknisi dan checklist | `live_dashboard.dart`, `service_orders_screen.dart` |
| 8. Sparepart, stok, ledger | `inventory_screen.dart`, `order_parts_screen.dart` |
| 9. Riwayat dan detail servis | `service_history_screen.dart` |
| 10. Invoice, pembayaran, laporan, profil | `payments_screen.dart`, `profile_screen.dart`, `invoice_pdf.dart` |

Komponen bersama: `WorkshopBody`, `BrandEmblem`, `BrandLockup`, `SessionSplash`,
`WorkshopIllustration`, `WorkshopWave`, `WorkshopHero`, `WorkshopRecordCard`,
`PageIntro`, `DashboardStatCard`, `QuickActionCard`, `SectionHeader`, timeline,
serta token warna, border, dan radius. Pemakaian komponen bersama menjangkau
layar detail/form tanpa menulis ulang controller dan repository.

Dialog konfirmasi, paginator, navigation shell, autentikasi, validasi,
repository, model, router, Firebase rules, dan kontrak transaksi dipertahankan.
Dialog/form yang sudah sesuai memakai tema bersama; tidak diberi alur baru.
Perubahan pada PDF hanya mengganti referensi logo.

## Keputusan visual dan perbedaan dari mockup

- Royal Blue `#2563EB`, Steel Navy `#1E3A5F`, off-white, dan amber mengikuti
  referensi. Panel biru muda memisahkan ringkasan dari form dan data.
- Radius kartu 16, border tipis, serta ruang antarbagian membantu membaca
  status dan tindakan. Kartu memakai tinggi alami supaya teks panjang muat.
- Ilustrasi otomotif memberi konteks halaman. Wave mengambil ruang 32dp
  sendiri, tidak menutup tombol, dan disembunyikan ketika keyboard terbuka.
- Tidak ada animasi dekoratif atau penundaan splash. Splash mengikuti sesi
  loading yang nyata lalu guard role yang sudah ada.
- Logo gear/wrench mockup menggantikan logo geometri lama sesuai instruksi
  lanjutan pengguna. Lima belas aset PNG dibuat dengan ImageGen; rincian ada
  di [manifest aset](MOCKUP_ASSETS.md). Ikon aksi kecil tetap Material agar
  tajam, memiliki tooltip/semantik, dan mengikuti ukuran teks.
- Reset password tetap memakai email pada layar masuk. Tidak ada Google
  login, notifikasi, field tahun kendaraan, atau alur baru yang tidak tersedia.
- Supplier/kategori stok dipertahankan karena model existing mendukungnya.
  Pembayaran tetap metode manual existing; tidak menambahkan QRIS/gateway.
- Grafik pada ilustrasi laporan bersifat dekoratif dan dikeluarkan dari
  semantics; tidak menyajikan seri angka palsu. Ringkasan tetap berasal dari
  provider dan menampilkan batas cakupan query existing.
- Timeline mengikuti state order; tidak mengarang timestamp tiap tahap.
  Label tindakan menjelaskan aksi tanpa mengubah transisi atau izin.

## Pemeriksaan visual dan aksesibilitas

Render di `docs/screenshots/mockup-alignment/` berasal dari widget Flutter
sebenarnya dengan font SDK dan **data fixture**, ukuran 390 x 740dp, raster 2x.
Ini bukan screenshot perangkat/emulator atau bukti transaksi production.
Capture dapat diulang dengan:

```sh
flutter test test/ui_ux_polish_test.dart --dart-define=CAPTURE_UI=true --plain-name "mockup alignment: capture actual Flutter screens with test fixtures"
```

Tes layout menelusuri layar per role pada 320dp dengan teks 200%; suite juga
mencakup 390/430/800dp, keyboard, navigasi, loading/error/empty/retry, dan
workflow existing. Overflow SectionHeader dan dropdown pada teks besar
diperbaiki dengan susunan adaptif dan item tinggi alami.

Kontras token terhitung: navy/biru muda 10.57:1, slate/off-white 7.24:1,
border kontrol/putih 4.76:1, putih/Royal Blue 5.17:1, Royal Blue/biru muda
4.75:1. Status memakai teks plus warna; kontras teks status pada tint putih
minimal 5.28:1. Ini audit token, bukan sertifikasi aksesibilitas menyeluruh.

## Quality gate

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter pub get` | PASS; dependency tidak diubah |
| `dart format --output=none --set-exit-if-changed .` | PASS; 73 file, 0 perubahan |
| `flutter analyze` | PASS; No issues found |
| `flutter test` | PASS; 95 tes |
| Capture fixture Flutter | PASS; 36 render diperiksa secara visual |
| `git diff --check` | PASS |
| `flutter build apk --debug` | PASS; exit 0, 419.6 detik |

Log lokal berada di
`build/mockup-final-tests.log`, `build/mockup-final-capture.log`,
`build/mockup-apk-final.log`, dan `build/mockup-final-analyze.log`.

APK lokal: `build/app/outputs/flutter-apk/app-debug.apk`, 192,374,869 byte.
Isi ZIP APK diverifikasi memuat logo mockup dan seluruh 14 PNG ilustrasi/wave.
SHA256: `1E31D0D92A8BD2D3A5F6ECE3505FE80B060D53AB21120C5C71EF9B8920A2C7FE`.
APK, log, dan cache build tidak dikomit. APK debug ini bukan ukuran rilis.

Native UAT Android: **NOT RUN**, tidak ada perangkat/emulator Android.
Native iOS build/render: **NOT RUN**, host Windows tidak menyediakan Xcode.
Print/share native dan UAT akun nyata: **NOT RUN**. Firebase rules tidak
diubah; tes rules tidak diulang pada pekerjaan UI ini.

Build toolchain memberikan peringatan existing tentang Kotlin Gradle Plugin
pada `firebase_auth`/`firebase_core` dan native access Java. Migrasi dependency
tidak dilakukan dalam scope UI. Aset sumber menambah bundle sekitar 20MB;
decode widget dibatasi ke ukuran render, tetapi PNG sumber tetap dibundel.

## Batas kesiapan

Perubahan siap ditinjau setelah gate lokal lulus. Masih perlu UAT perangkat
Android, verifikasi launch/iOS pada macOS, dan print/share native sebelum
penerimaan akhir. Phase 07 dan Phase 08 tidak dimulai. Tidak ada deployment
Firebase production atau auto-merge.
