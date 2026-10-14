# Laporan Flutter Mobile Foundation — BengkelKu

Tanggal: 14 Oktober 2026 (Asia/Jakarta). Lingkungan: Windows, Flutter 3.44.2,
Dart 3.12.2, Android SDK 36.1.0, JDK 21. Implementasi melanjutkan prototype;
Riverpod, GoRouter, Material 3, serta target web/desktop dipertahankan.

## Audit awal

- Working tree awal bersih, branch awal main. Tidak ditemukan AGENTS.md yang berlaku.
- origin fetch/push: https://github.com/Freddy47588/Aplikasi-Bengkel.git.
- Branch kerja: fix/mobile-foundation; tidak menggunakan force push.
- Router sebelumnya dibuat ulang setiap sesi berubah tanpa lifecycle disposal.
- Menu bar/rail tidak menangani pilihan; index selalu 0.
- Menu Teknisi Admin menuju route Teknisi sehingga ditolak guard Admin.
- Form booking, tombol konfirmasi/detail, dan sejumlah menu memiliki callback kosong.
- Customer/Admin memakai list booking statis; status berupa String dan jadwal berupa teks.
- Statistik, kendaraan, riwayat, stok, pekerjaan teknisi, reminder dan pembayaran masih hardcoded.
- Grid statistik, kartu quick action, baris tombol/status berisiko overflow pada layar kecil.
- Android memakai identifier contoh, label template, ikon Flutter dan debug key untuk release.
- iOS memakai identifier contoh/nama lama, AppIcon template dan splash kosong.
- pubspec meminta Dart 3.13.5 sementara SDK lokal Dart 3.12.2; pub get awal gagal.

## Perbaikan dan fitur berjalan

Router stabil memakai listen sesi dan refreshListenable; router/notifier dibersihkan
ketika ProviderScope dibuang. Redirect/guard role diuji. Navigasi bersama membaca
route aktif untuk selectedIndex. Teknisi Admin memiliki route sendiri dan tombol
kembali menuju dashboard Admin. Menu yang belum diimplementasikan memberi status
belum tersedia; history/profile mempunyai tujuan valid dengan batas demo jelas.

Booking menggunakan BookingDraft, Booking, Vehicle dan enum BookingStatus.
Repository abstraction menyediakan watch, submit, updateStatus, dispose.
In-memory repository mempertahankan data lintas login/logout pada satu ProviderScope.
Pelanggan memilih kendaraan/layanan/tanggal/jam, menulis keluhan, memvalidasi,
meninjau dialog, mengirim, membuka detail, dan membatalkan. Admin melihat booking
yang sama dan dapat mengonfirmasi/menolak. Stream mengirim snapshot terbaru ke
pelanggan/admin; duplicate vehicle/time, ownership, dan transisi terminal dilindungi.
Booking mock lama diganti domain baru; pekerjaan teknisi demo tetap dipertahankan.

Pembacaan booking memiliki loading, empty, error/retry; mutasi menampilkan loading,
error, dan snackbar success. SafeArea/scrolling login dan form diperbaiki; status
pekerjaan tidak memakai trailing yang memakan lebar; kartu/tombol dashboard
menyesuaikan ruang layar. Uji mencakup 320x568, 430x932, 1280x800 pada teks 1.3x,
serta keyboard 250px di layar kecil.

Android namespace/applicationId dan iOS Runner bundle identifier menjadi
id.bengkelku.mobile (verifikasi kepemilikan sebelum distribusi). Nama aplikasi
BengkelKu. MainActivity dipindahkan mengikuti package. Android release unsigned,
bukan debug-signed, sampai keystore produksi asli dikonfigurasi. Gradle dibatasi
2GB heap, 2 worker, dan Kotlin daemon 1GB setelah build awal berjalan sangat lambat
pada konfigurasi lama 8GB. Tidak ada signing iOS palsu. Deployment target iOS 15.0
existing dipertahankan. Aset ikon/splash lokal digambar dengan geometri B;
seluruh AppIcon PNG memakai RGB tanpa kanal alpha dan mengikuti ukuran katalog.
README berisi setup, batas demo, perintah validasi, dan roadmap lima modul TA.

## Validasi

| Pemeriksaan | Hasil |
| --- | --- |
| flutter pub get | PASS setelah SDK constraint diperbaiki; direct Riverpod/GoRouter tetap |
| dart format . | PASS |
| flutter analyze | PASS — No issues found |
| flutter test | PASS — 16 tests |
| flutter build apk --debug | PASS ? build/app/outputs/flutter-apk/app-debug.apk (157,731,517 byte), Gradle 1m36s |
| Build iOS | iOS build NOT VERIFIED — Windows tanpa Mac/Xcode |

Cakupan test: login/logout tiga role, actual router lifecycle/guard/index,
validasi setiap input, submit invalid/valid, duplikat, ownership, terminal status,
stream dua subscriber, alur UI Customer/Admin/Customer, pembatalan,
loading/empty/error/retry, keyboard dan ukuran layar.
APK manifest hasil build memuat package `id.bengkelku.mobile`, label `BengkelKu`,
dan activity `id.bengkelku.mobile.MainActivity`. Gradle melaporkan
deprecation yang perlu diaudit sebelum Gradle 10; build debug tetap sukses.
Dependency langsung mendukung Android/iOS pada metadata package; resolver,
analyzer, dan widget test lulus. Build iOS/native device belum terbukti.
Tidak ada perangkat Android/iPhone terhubung untuk uji visual native;
tidak ada screenshot aplikasi yang diklaim. Flutter doctor mencatat sebagian
lisensi SDK Android belum diterima; review dengan flutter doctor --android-licenses
jika akan memakai komponen SDK tambahan.

## Technical debt dan Phase 2

Data in-memory hilang saat restart/hot restart dan tidak sinkron antar-perangkat.
Login/identitas kendaraan masih demo, belum multi-user/backend RBAC.
Kapasitas slot, durasi layanan, hari libur, timezone bengkel, notifikasi, assignment
teknisi dan modul pembayaran/inventori/laporan belum diterapkan. Statistik yang
bukan jumlah booking dan riwayat servis tetap contoh data berlabel demo.
Signing distribusi Android/iOS dan verifikasi native iPhone masih diperlukan.
APK debug 157 MB merupakan artefak pengembangan, bukan ukuran release.

Phase 2: implementasi repository persisten dengan identitas pelanggan dan
otorisasi backend, migrasi katalog kendaraan/layanan, kapasitas booking transaksional,
CI Android/iOS, uji perangkat/emulator, serta signing asli. Selanjutnya kerjakan
Service Order/teknisi, inventori dan pembayaran/laporan sesuai roadmap README;
modul-modul itu tidak dibuat pada fase perbaikan ini.

## Git

Commit/push dilakukan setelah review diff dan validasi akhir. Hash commit dan
hasil push dilaporkan pada respons penyelesaian; gunakan git log -1 untuk identitas
commit laporan ini. Tidak ada force push dan tidak ada pekerjaan awal yang ditimpa.
Aset build/log/SDK lokal tidak dimasukkan commit. File signing umum diabaikan.

## Daftar file berubah

- `.gitignore`
- `README.md`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/bengkel_kendaraan/MainActivity.kt`
- `android/app/src/main/kotlin/id/bengkelku/mobile/MainActivity.kt`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/main/res/values-v31/styles.xml`
- `android/gradle.properties`
- `docs/mobile-foundation-report.md`
- `ios/Runner.xcodeproj/project.pbxproj`
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
- `ios/Runner/Info.plist`
- `lib/app/router/app_router.dart`
- `lib/core/data/booking_repository.dart`
- `lib/core/data/mock_workshop_data.dart`
- `lib/core/models/booking.dart`
- `lib/core/models/workshop_models.dart`
- `lib/core/widgets/empty_state.dart`
- `lib/core/widgets/foundation_pages.dart`
- `lib/core/widgets/mobile_navigation.dart`
- `lib/core/widgets/quick_action_card.dart`
- `lib/core/widgets/section_header.dart`
- `lib/core/widgets/status_chip.dart`
- `lib/features/admin/presentation/admin_bookings_screen.dart`
- `lib/features/admin/presentation/admin_dashboard_screen.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/customer/presentation/customer_booking_screen.dart`
- `lib/features/customer/presentation/customer_dashboard_screen.dart`
- `lib/features/technician/presentation/technician_dashboard_screen.dart`
- `lib/features/technician/presentation/technician_jobs_screen.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/booking_repository_test.dart`
- `test/mobile_foundation_test.dart`
- `tools/generate-brand-assets.ps1`
