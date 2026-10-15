# BengkelKu

Aplikasi Flutter Android/iOS untuk akun pelanggan, kendaraan, booking dan pekerjaan bengkel.
Phase 04 menggunakan Firebase Auth Email/Password dan Cloud Firestore pada project
asli `bengkelku-app-bebd9`, tanpa billing/Blaze, Storage, Functions atau SMS OTP.

## Fitur

- Register pelanggan, login/logout, forgot password, verifikasi email dan sesi native Firebase.
- Profil role tepercaya dan akun nonaktif; login demo/pemilihan role dihapus.
- CRUD kendaraan milik pelanggan, normalisasi/validasi plat dan archive.
- Katalog layanan Firestore aktif, tanpa seed data palsu.
- Booking kendaraan + layanan + jadwal WIB + keluhan; stream data lintas client.
- Admin confirm/reject; pelanggan cancel sesuai transisi legal.
- Kapasitas satu booking per jam bengkel, transaksi lock + security rules default-deny.
- Direktori teknisi admin dengan pencarian/filter dan pagination; role tetap diprovision operator tepercaya.
- Service Order unik per booking confirmed; assignment transaksional dengan lock teknisi.
- Pekerjaan teknisi sendiri, checklist, diagnosis, tindakan, catatan dan progres realtime pelanggan.
- Start/pause/finish, persetujuan admin, revision dan event audit immutable.
- Daftar SO dan teknisi memakai cursor pagination 20 dokumen; dashboard teknisi memakai pekerjaan nyata.
- Master sparepart admin dengan SKU unik, harga integer rupiah, kategori, satuan, supplier opsional dan arsip.
- Ledger immutable stok masuk/koreksi/pemakaian/reversal, saldo atomik, idempotency dan stok minimum.
- Permintaan teknisi → approval admin, snapshot sparepart/harga pada SO; customer membaca pemakaian miliknya.
- Riverpod, repository abstraction, GoRouter stabil dan Material 3 dipertahankan.

## Menjalankan

Status dan batas verifikasi terbaru: [laporan Phase 04](docs/PHASE_04_REPORT.md).

```sh
flutter pub get
flutter run -d <android-device>
```

Android `id.bengkelku.mobile` dikonfigurasi melalui FlutterFire CLI menggunakan
app Firebase asli. Konfigurasi client sudah tersedia; kredensial Admin SDK dan
signing privat tidak disimpan. iOS harus dikonfigurasi di Mac/Xcode melalui CLI,
kemudian native build dan smoke test. Build iOS belum diverifikasi di Windows.

**Rules/indexes production belum dideploy.** Aplikasi memerlukan review/deploy
rules dan setup katalog/akun pegawai sebelum acceptance production.
Lihat [setup Firebase lengkap](docs/FIREBASE_SETUP.md) untuk Android/iOS,
provisioning role lewat operator tepercaya, schema, indeks, batas kuota,
transaksi slot, pengujian emulator dan prosedur review deploy.

## Validasi

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
npm ci --no-audit --no-fund
npm run test:rules
```

SDK lokal: Flutter 3.44.2 / Dart 3.12.2. Test emulator memakai demo project lokal,
bukan project produksi. Hasil dan keterbatasan: [laporan Phase 02](docs/PHASE_02_REPORT.md).
Riwayat Phase 01: [status fondasi](docs/PHASE_STATUS.md) dan
[laporan fondasi](docs/mobile-foundation-report.md).

## Batas fase ini

- Slot kapasitas satu, belum menghitung durasi servis, bay/teknisi atau hari libur.
- Kueri maksimal 50 kendaraan, 50 layanan dan 100 booking terbaru; belum pagination.
- Archive kendaraan tidak menghapus snapshot booking. Keunikan plat belum dipaksakan.
- Operator mengisi katalog di Console; UI CRUD katalog admin belum tersedia.
- Service Order, pekerjaan teknisi, inventori, pembayaran dan laporan belum produksi.
- Tidak ada uji dua perangkat Android atau native iPhone pada host ini.
- Auth/session cache native setelah process kill dan email produksi perlu smoke test perangkat.
- Release Android tetap unsigned sampai keystore asli disiapkan; iOS perlu Team asli.

Scope berhenti pada Phase 02. [Roadmap](docs/ROADMAP.md).
