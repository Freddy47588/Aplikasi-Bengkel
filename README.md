# BengkelKu

Rancang Bangun Aplikasi Mobile Sistem Manajemen Bengkel Berbasis Flutter.
Perbaikan ini melanjutkan prototype yang ada dengan satu codebase mobile-first
untuk Android dan iOS. Target Windows, web, Linux, dan macOS tetap tersedia.

## Teknologi

- Flutter Material 3, Dart >=3.12.2 <4.0.0; validasi lokal Flutter 3.44.2 / Dart 3.12.2.
- Riverpod 3.4.3 untuk sesi dan stream booking; GoRouter 18.0.2 untuk navigasi/role guard.
- Repository abstraction dengan implementasi in-memory; tanpa Firebase pada fase ini.
- Dependency langsung mendukung Android/iOS berdasarkan metadata package:
  [Riverpod](https://pub.dev/packages/flutter_riverpod),
  [GoRouter](https://pub.dev/packages/go_router),
  [Cupertino Icons](https://pub.dev/packages/cupertino_icons).
  Resolusi dependency dan build Android diuji lokal; kompatibilitas native iOS
  masih harus dibuktikan dengan Xcode.

## Fitur yang bekerja

- Login/logout demo Pelanggan, Teknisi, Admin; router tetap hidup selama pergantian sesi.
- Redirect tamu ke login, pembatasan route per role, navigasi mengikuti route aktif.
- Menu Teknisi Admin membuka daftar pekerjaan demo melalui route Admin.
- Booking: pilihan kendaraan, layanan, tanggal, jam, keluhan, validasi, review sebelum kirim.
- Daftar/detail booking, pembatalan pelanggan, konfirmasi/penolakan Admin.
- Status bertipe `BookingStatus`: pending, confirmed, rejected, cancelled.
- Stream bersama: booking Customer terlihat oleh Admin; perubahan Admin terlihat oleh Customer.
- Loading/empty/error/retry pada pembacaan booking; loading/error/success pada perubahan.
- SafeArea, scrolling, form dengan keyboard, layout dashboard untuk layar kecil/besar.
- Ikon lokal Android/iOS, splash sederhana, nama aplikasi BengkelKu.

## Batas demo

Login merupakan pemilihan role, belum autentikasi produksi. Semua pelanggan demo
menggunakan identitas `customer-demo` dan dua kendaraan contoh. Daftar layanan/jam
masih katalog lokal. Data hanya hidup di ProviderScope aplikasi: logout mempertahankan
booking supaya dapat diuji antar-role, restart/hot restart menghapus seluruh data.
Dua perangkat, tab browser, atau proses aplikasi tidak saling menyinkronkan.

Booking hanya menolak duplikat kendaraan pada waktu yang sama. Kapasitas bengkel,
durasi servis, hari libur, zona waktu bengkel, dan konflik antar-kendaraan belum diatur.
Jadwal menggunakan waktu lokal perangkat, di masa depan hingga 90 hari;
jam 09, 10, 11, 13, 14, 15, 16; keluhan 5-500 karakter.
Pelanggan boleh membatalkan pending/confirmed; Admin hanya mengubah pending
menjadi confirmed/rejected. Status terminal tidak bisa diubah kembali.

Pekerjaan/checklist/progres teknisi, statistik servis/pendapatan, stok, riwayat servis,
reminder dan pembayaran yang ada masih contoh data dan diberi label demo.
Antrean dan Service Order sementara menuju daftar booking; operasi modul tersebut
belum diimplementasikan. Menu modul lanjutan menampilkan pesan belum tersedia.
Profil hanya menunjukkan sesi demo. Guard lokal bukan keamanan backend.

## Instalasi dan run

```sh
flutter --version
flutter doctor -v
flutter pub get
flutter devices
flutter run -d <device-id>
```

Gunakan SDK dengan Dart >=3.12.2. Lockfile sudah disesuaikan dengan SDK lokal;
Riverpod dan GoRouter dipertahankan. Web dapat dijalankan dengan
`flutter run -d chrome`. Target desktop tidak dihapus; build desktop tidak divalidasi di fase ini.

## Android setup

1. Instal Flutter, Android Studio, SDK/toolchain yang dilaporkan `flutter doctor`.
2. Jalankan `flutter doctor --android-licenses`, tinjau dan terima lisensi yang diperlukan.
3. Siapkan emulator atau perangkat dengan USB debugging, lalu `flutter devices`.
4. Jalankan `flutter run -d <android-device-id>` atau `flutter build apk --debug`.

Namespace/applicationId: `id.bengkelku.mobile`; package MainActivity sama.
compileSdk/minSdk/targetSdk/NDK mengikuti Flutter SDK, Java/Kotlin bytecode 17.
Identifier ini untuk fondasi pengembangan; verifikasi kepemilikan dan keunikan sebelum rilis toko.
APK debug berada di `build/app/outputs/flutter-apk/app-debug.apk`.

Release **tidak memakai debug signing** dan belum siap distribusi. `signingConfig = null`
menghasilkan release unsigned sampai keystore rilis asli disiapkan. Konfigurasikan signing
privat dan CI saat akan distribusi; jangan commit keystore, password, atau key.properties.
`.gitignore` melindungi file signing umum. Tidak ada keystore/credential rilis yang dibuat.

## iOS setup (Mac + Xcode)

1. Instal Flutter dan Xcode beserta command line tools; jalankan `flutter doctor -v`.
2. Dari root jalankan `flutter pub get`, buka `ios/Runner.xcworkspace` di Xcode.
3. Bundle identifier Runner: `id.bengkelku.mobile`; RunnerTests memakai suffix `.RunnerTests`.
4. Deployment target project: iOS 15.0. Pilih simulator/perangkat melalui `flutter devices`.
5. Untuk perangkat/distribusi, pilih Apple Development Team milik Anda dan konfigurasi signing asli.
6. Jalankan `flutter run -d <ios-device-id>`, `flutter build ios --simulator`,
   kemudian build/archive perangkat sesuai provisioning yang valid.

Nama Info.plist: BengkelKu; AppIcon dan LaunchImage berada di Assets.xcassets.
Tidak ada Team ID, sertifikat, atau provisioning palsu.
**iOS build NOT VERIFIED**: pekerjaan ini dilakukan di Windows tanpa Mac/Xcode.
Widget test Flutter bukan bukti build atau perilaku native iPhone.

## Aset dan screenshot

Ikon geometris B tersedia lokal di
[AppIcon 1024px](ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png).
Untuk menghasilkan ulang aset yang sama di Windows, jalankan dari root:
`powershell -File tools/generate-brand-assets.ps1`.
Script menggambar geometri sederhana dan mengisi ukuran katalog Android/iOS.
Screenshot aplikasi belum tersedia; tidak ada tautan screenshot buatan.

## Testing

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

Test meliputi login/logout tiga role, router tidak dibuat ulang, guard role,
selectedIndex, validasi booking, duplikat, ownership, transisi status,
submission form, konfirmasi Admin, status Customer, pembatalan, serta
layar 320x568, 430x932, 1280x800 dengan teks 1.3x.
Hasil akhir dan audit ada di [laporan fondasi](docs/mobile-foundation-report.md).

## Roadmap lima modul TA

1. Akun dan kendaraan: autentikasi produksi, RBAC backend, profil, CRUD kendaraan.
2. Booking dan antrean: repository persisten, kapasitas slot, kalender bengkel, notifikasi.
3. Service Order dan teknisi: assignment, checklist, progres, riwayat pengerjaan.
4. Sparepart dan inventori: master barang, mutasi, pemakaian servis, stok minimum.
5. Pembayaran dan laporan: invoice, verifikasi pembayaran, laporan servis/pendapatan.

Phase 2 disarankan memprioritaskan persistensi, identitas pelanggan, dan kapasitas booking,
kemudian verifikasi native Android/iPhone dan signing produksi. Modul lain tetap roadmap.
