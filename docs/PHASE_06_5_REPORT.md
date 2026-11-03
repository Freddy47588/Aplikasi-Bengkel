# Phase 06.5 — universal BengkelKu UI/UX polish

2–3 November 2026, Asia/Jakarta. Repository `Freddy47588/Aplikasi-Bengkel`.
Base `origin/main`: `12583b2a97974eb72f358d0b2bd687dd3cce555c` (Phase 01–06).
Branch: `refactor/ui-ux-polish`, worktree `Aplikasi-Bengkel-ui-ux`.

## Perubahan

Identitas universal BengkelKu menggunakan Steel Navy `#1E3A5F`, Royal Blue
`#2563EB`, Amber `#F59E0B`, Off-white `#F8FAFC`, dan Slate Gray `#64748B`.
Amber hanya menjadi aksen; tombol utama Royal Blue dengan teks putih.
Tidak ada nama personal atau label edition dalam UI/branding.

Melanjutkan perubahan lokal yang sudah ada di branch ini, lalu menyesuaikannya
dengan scope universal biru. Checkout `main` yang memiliki perubahan lokal
dipertahankan. Tidak membuat proyek baru atau menambah dependency aplikasi;
lockfile dipertahankan. Komponen Flutter/Material 3, Riverpod, GoRouter, serta
repository existing tetap digunakan.

Design system merapikan spacing 4/8/12/16/24/32dp, radius 12/20/24dp,
kartu putih tanpa shadow berat, input, tombol, badge status, section header,
empty/loading/error state, retry, feedback, dan dialog konfirmasi scrollable.
Konten dibatasi 960dp; kartu memakai tinggi alami dan grid adaptif 1–3 kolom.
Target sentuh tombol minimal 48dp, tombol utama minimal 52dp.

| Area | Layar dan perbaikan |
| --- | --- |
| Auth | Login/register, forgot password, status/verifikasi akun; branding, password visibility, feedback dan keyboard/scroll |
| Customer | Dashboard dengan aksi utama langsung terlihat, booking form/list/detail, kendaraan, progres/timeline, riwayat/filter/detail, invoice/PDF, profil akun |
| Admin/kasir | Dashboard, kelola booking/detail, teknisi, service order/detail, inventory/master, stok masuk/keluar/ledger, permintaan sparepart, pembayaran/invoice/audit, laporan, profil |
| Technician | Dashboard, jobs/order/detail, timeline/checklist, diagnosis/tindakan/catatan, permintaan part, riwayat dan profil |

Navigasi bawah mengikuti route daftar/detail dan area produknya. Profil
menampilkan email, role, status akun/verifikasi serta reset password dari sesi
existing. Dashboard menunjukkan batas data provider, bukan statistik rekaan.
Ringkasan booking maksimal 100; order maksimal 20 pada halaman terbaru.

Inventory menampilkan nama sparepart lebih dahulu; pencarian tetap awalan kode
dan kategori persis sesuai repository, dijelaskan melalui helper text. Arsip
sparepart memerlukan konfirmasi dan mencegah dialog ganda. Riwayat memakai
label nama/plat/jenis servis, termasuk kendaraan customer yang diarsipkan.
Jenis servis nonaktif tetap dapat dipilih dari snapshot pada halaman riwayat
yang dimuat, tanpa membaca katalog nonaktif atau menambah query. Pembayaran
riwayat mengikuti dokumen invoice realtime dengan penanda cache;
teknisi tidak mengeluarkan query invoice. Invoice memisahkan status, rincian
biaya, total/saldo, PDF, tindakan kasir, dan audit. Label kendaraan demo dan
status pembayaran statis yang menyesatkan dihapus.

## Branding

Emblem mekanis berupa housing hex dan rotor enam gigi, digambar dari koordinat
sendiri tanpa artwork pihak ketiga atau huruf personal. SVG adalah sumber
geometri; generator PowerShell existing menghasilkan PNG Flutter/PDF,
launcher legacy/adaptive Android, vector foreground Android 12+, wordmark
splash, seluruh ikon katalog iOS, dan launch image iOS.

Nama aplikasi tetap BengkelKu. Latar launcher/splash Steel Navy konsisten,
termasuk konfigurasi night Android. Header PDF mengikuti identitas yang sama.
Panduan lengkap: [BRANDING_GUIDE.md](BRANDING_GUIDE.md).

Render visual final disimpan di `docs/screenshots/fixture-*.png`. Ini hasil
widget Flutter dengan FakeFirestore dan font SDK pada 390dp/skala teks 1,3×,
bukan bukti UAT akun Firebase atau screenshot perangkat native. Screenshot
lokal sebelum penyesuaian branding disimpan di arsip `build/` yang diabaikan Git.

## Hasil pengujian

Hasil berikut berasal dari run pada perubahan ini, bukan laporan lokal sebelumnya.

| Pemeriksaan | Hasil run saat ini |
| --- | --- |
| `dart format .` | PASS; format seluruh 73 file Dart |
| `flutter pub get` | PASS; dependency existing, lockfile tidak berubah |
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 91 tes, 0 gagal; termasuk filter jenis servis nonaktif dan pagination pada 320dp |
| Render Flutter 390dp/1,3× | PASS — 7 tes; tiga dashboard dan login final ditinjau |
| `npm run test:rules` | PASS — 35 tes, 0 gagal, Auth/Firestore emulator `demo-bengkelku` |
| `flutter build apk --debug` | PASS — build final 49,7 detik; build pertama pada cache kosong 2652,8 detik |
| XML native dan ikon iOS | PASS: 11 XML native dan 19 entri ikon iOS sesuai ukuran katalog, PNG RGB opaque |
| Geometri adaptive icon | PASS: seluruh simbol berada dalam safe circle radius 33dp pada canvas 108dp |
| Native iOS | **NOT VERIFIED** — host Windows, tanpa macOS/Xcode |
| UAT Firebase tiga role / native print-share PDF | **NOT VERIFIED** — memerlukan akun uji dan perangkat yang diotorisasi |

Regresi mencakup authentication/role guard, realtime booking, kendaraan,
assignment/transisi/checklist service order, inventory/idempotency, riwayat,
pembayaran, invoice/PDF dan laporan. Widget tests memeriksa dashboard tiga role
pada 320/360/390/430/800dp dan regresi tablet 1280dp, skala teks 1,3×, keyboard,
navigasi daftar/detail, loading/empty/error/retry, invoice realtime/cache,
visibilitas tindakan sesuai role, serta pembatalan konfirmasi arsip.

Firebase project ID, application/bundle identifier, schema, model transaksi,
repository write, role/permission, Security Rules dan indexes tidak diubah.
`invoice_pdf.dart` hanya mengubah header visual. Query invoice pada riwayat
mengikuti akses customer/admin existing, tanpa memperluas izin teknisi.


APK final: `build/app/outputs/flutter-apk/app-debug.apk`.
Ukuran: 170987964 byte. SHA256: `51F53A08173530B7D89F4B6B57DE5EECC4D639B19F52C42D3650249870EAE097`.
Dibangun 3 November 2026, 10:11:53 WIB. Package
`id.bengkelku.mobile`, label BengkelKu, MainActivity dan tiga ABI
(arm64-v8a, armeabi-v7a, x86_64) diperiksa melalui APK. Emblem dalam bundle
APK cocok dengan aset sumber final. APK/log/cache lokal tidak dikomit.

## Keterbatasan dan kesiapan Phase 07

- Build/smoke native iOS membutuhkan Mac/Xcode dan konfigurasi Firebase iOS
  asli sesuai panduan setup existing; audit aset bukan verifikasi native.
- UAT dengan akun customer/admin/technician dan perangkat Android/iOS nyata,
  keyboard native, cold start, serta print/share PDF masih perlu dilakukan.
- Dashboard/filter mengikuti batas query provider existing. Pilihan kendaraan
  admin/teknisi berasal dari halaman riwayat yang dimuat; tidak ada query/index
  baru untuk pencarian lintas halaman.
- Toolchain existing masih mengeluarkan warning KGP dan metadata SDK. Migrasi
  toolchain perlu direncanakan terpisah; warning tidak menggagalkan build ini.
- Security Rules/indexes produksi tidak dideploy. Risiko backend pada laporan
  Phase 06 tetap berlaku; fase UI tidak mengubah kontrak backend.
- Android SDK/cache package komputer ini tidak lengkap saat mulai. Pemulihan
  tooling lokal tidak dimasukkan ke commit atau dependency aplikasi. Gradle dan
  NDK diverifikasi dengan checksum resmi. Emulator rules pada JBR/Windows
  memakai fallback TCP lokal untuk mengatasi kegagalan socket internal Java;
  tidak ada perubahan pada aplikasi atau konfigurasi Firebase produksi.

Implementasi Phase 06.5 siap direview sebagai dasar Phase 07. Native iOS dan
UAT perangkat/akun nyata tetap menjadi acceptance berikutnya.
**STOP pada Phase 06.5. Phase 07 tidak dimulai.**

## Git

Origin diperiksa dan `git fetch origin` berhasil. Branch existing sudah berada
di base main terbaru; perubahan hanya dibuat pada worktree UI.
Commit yang digunakan:
`refactor: polish universal BengkelKu UI UX with blue identity`.
Branch tujuan: [refactor/ui-ux-polish](https://github.com/Freddy47588/Aplikasi-Bengkel/tree/refactor/ui-ux-polish).
PR menargetkan `Freddy47588:main`; URL PR disampaikan pada laporan akhir.
Publikasi memakai konektor GitHub karena kredensial Git lokal tidak tersedia;
isi file diverifikasi terhadap SHA blob Git lokal. Tidak ada force push,
push langsung ke main, atau auto-merge.

## Daftar file

File yang diubah (56):

- `README.md`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values-v31/styles.xml`
- `docs/PHASE_STATUS.md`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png`
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png`
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- `lib/app/router/app_router.dart`
- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_theme.dart`
- `lib/core/data/invoice_pdf.dart`
- `lib/core/widgets/foundation_pages.dart`
- `lib/core/widgets/live_dashboard.dart`
- `lib/core/widgets/mobile_navigation.dart`
- `lib/core/widgets/quick_action_card.dart`
- `lib/core/widgets/status_chip.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/customer/presentation/customer_booking_screen.dart`
- `lib/features/customer/presentation/service_history_screen.dart`
- `lib/features/customer/presentation/vehicles_screen.dart`
- `lib/features/inventory/presentation/inventory_screen.dart`
- `lib/features/inventory/presentation/order_parts_screen.dart`
- `lib/features/payments/presentation/payments_screen.dart`
- `lib/features/technician/presentation/service_orders_screen.dart`
- `lib/features/technician/presentation/technician_dashboard_screen.dart`
- `lib/features/technician/presentation/technicians_screen.dart`
- `pubspec.yaml`
- `test/inventory_widgets_test.dart`
- `test/mobile_foundation_test.dart`
- `test/service_history_widgets_test.dart`
- `test/service_order_widgets_test.dart`
- `test/test_support.dart`
- `tools/generate-brand-assets.ps1`

File baru (27):

- `android/app/src/main/res/drawable-hdpi/brand_wordmark.png`
- `android/app/src/main/res/drawable-mdpi/brand_wordmark.png`
- `android/app/src/main/res/drawable-nodpi/splash_lockup.png`
- `android/app/src/main/res/drawable-xhdpi/brand_wordmark.png`
- `android/app/src/main/res/drawable-xxhdpi/brand_wordmark.png`
- `android/app/src/main/res/drawable-xxxhdpi/brand_wordmark.png`
- `android/app/src/main/res/drawable/brand_emblem.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/values-night-v31/styles.xml`
- `android/app/src/main/res/values/colors.xml`
- `assets/branding/emblem.png`
- `assets/branding/emblem.svg`
- `assets/branding/launcher-master.png`
- `assets/branding/splash-lockup.png`
- `docs/BRANDING_GUIDE.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/PHASE_06_5_REPORT.md`
- `docs/UI_UX_AUDIT.md`
- `docs/screenshots/fixture-admin-dashboard-390.png`
- `docs/screenshots/fixture-customer-dashboard-390.png`
- `docs/screenshots/fixture-login-390.png`
- `docs/screenshots/fixture-technician-dashboard-390.png`
- `lib/app/theme/app_tokens.dart`
- `lib/core/widgets/history_payment_summary.dart`
- `lib/core/widgets/workshop_ui.dart`
- `lib/features/auth/presentation/profile_screen.dart`
- `test/ui_ux_polish_test.dart`
