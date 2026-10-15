# Phase 02 — Firebase Auth, Vehicles and Bookings

Audit: 15 Oktober 2026, Asia/Jakarta. Branch `feat/firebase-auth-booking`.
Base fork `Freddy47588:main` pada `9413c42` (Phase 01 final merged via PR #2).

## Pre-flight dan konfigurasi

- Remote fetch/push hanya `https://github.com/Freddy47588/Aplikasi-Bengkel.git`.
- Branch existing di-fast-forward ke `origin/main`. Tidak ada reset, force push,
  stash atau perubahan lokal awal yang dibuang. Tidak ditemukan AGENTS.md berlaku.
- Perubahan Firebase awal (dependency, Gradle, registrant, config) diintegrasikan.
  File kosong awal `1.3` dan `customer` dipertahankan lokal, tidak masuk commit.
- CLI memverifikasi project asli `bengkelku-app-bebd9`, Android app
  `1:932140419370:android:f69ab7bc5097462078b653`, package `id.bengkelku.mobile`.
- Firestore Native Standard `(default)` di `asia-southeast2`, `freeTier: true`.
  Pemeriksaan API read-only: Email/Password enabled, passwordRequired true,
  billingEnabled false. Tidak ada upgrade billing atau layanan berbayar lain.
- `flutterfire configure --project=bengkelku-app-bebd9 --platforms=android
  --android-package-name=id.bengkelku.mobile --yes` berhasil.

## Hasil implementasi

Login role demo dan default repository in-memory dihapus dari aplikasi; fixture
tetap hanya di test. Auth memakai repository, listener ID token dan profil users
yang dapat dibatalkan saat berganti akun. Register selalu customer, pembuatan
profil idempotent, login tidak menimpa role/active. Ada forgot password, resend
verification, refresh token, logout dengan loading/error, redirect loading/
unverified/missing profile/disabled, dan refresh Auth saat foreground.

Vehicles CRUD dengan owner immutable, validasi/normalisasi plat dan archive;
layanan dibaca dari Firestore aktif. Booking menyimpan snapshot server kendaraan
dan layanan. Admin trusted dapat melihat dan confirm/reject; customer dapat
cancel booking sendiri. Slot canonical WIB kapasitas satu memakai transaksi
dan rules getAfter, termasuk pelepasan atomik dan reuse. Kueri difilter dan
dibatasi; dashboard menyatakan cakupan 100 booking terbaru, tanpa statistik palsu.

Rules default-deny membatasi data pemilik, claim email verification, active,
role, field write, timestamp server, transisi dan lock. Update role/active hanya
operator tepercaya melalui Console/Admin SDK. Teknisi belum menerima akses booking
pelanggan. Rules, indexes, test emulator dan prosedur provisioning ada di repo.

## Validasi lokal

| Pemeriksaan | Hasil |
| --- | --- |
| flutter pub get | PASS; firebase_core 4.15.0, firebase_auth 6.7.0, cloud_firestore 6.10.0 |
| dart format . | PASS, 43 file; pemeriksaan terakhir 0 perubahan |
| flutter analyze | PASS, No issues found |
| flutter test | PASS, 32 tests |
| npm install --no-audit --no-fund | PASS, package-lock disimpan untuk npm ci |
| npm run test:rules | PASS, 10 tests Auth + Firestore Emulator, 0 fail |
| flutter build apk --debug | PASS, assembleDebug 341.1 detik setelah perbaikan cache Kotlin |
| git diff --check | PASS |
| Scan private credential kandidat diff | Tidak ditemukan pola PEM private key, GitHub token, refresh token atau service-account private key |
| Native iOS | NOT VERIFIED; Windows tanpa Mac/Xcode; konfigurasi iOS belum dibuat |
| Dua perangkat Android | NOT RUN; adb devices tidak menunjukkan perangkat terhubung |
| Production E2E | NOT RUN; tidak membuat akun/data test di project asli |

APK debug: `build/app/outputs/flutter-apk/app-debug.apk`, 164,505,812 byte.
SHA256: `B7B9D2549CDA25F961D74FE3D89A3050BC752656544AF24B018DB01DDD0FC39B`. APK/cache/log tidak masuk commit.

Flutter tests mencakup repository auth asli dengan Auth mock dan Firestore fake,
profil customer/role existing, verification failure retry, user disabled, pergantian
listener akun, kendaraan create/edit/archive/ownership, snapshot booking dan status,
redirect, auth form/loading/error/reset/logout, CRUD UI kendaraan, booking UI
customer→admin→customer, keyboard dan layout 320/360/390/430/1280dp pada text scale 1.3.

Emulator tests memakai project lokal `demo-bengkelku`, tidak mengirim email ke
provider nyata: register, verifikasi kode OOB lokal, login client baru, data vehicle
persisted dan password reset. Firestore rules menguji A tidak mengakses B, tidak
self-promote, admin catalog/booking, unknown fields/ownership/timestamp immutable,
unverified/inactive denial, transisi terminal, booking+lock atomik dan bentrok.
Dua transaksi concurrent akun berbeda menghasilkan tepat satu booking; lock
tidak dapat dicuri/release sendiri, lalu dapat dipakai ulang setelah cancel.

Build Android awal gagal pada incremental cache Kotlin: source plugin berada di
pub cache C:, sedangkan repo di D:. `kotlin.incremental=false` ditambahkan dengan
komentar dan prosedur di setup; konsekuensinya kompilasi Kotlin dapat lebih lambat.
Plugin Firebase core/auth masih mengeluarkan warning penggunaan KGP yang perlu
ditinjau sebelum upgrade Flutter berikutnya. Tidak ada error analyzer Dart.

## Batas penerimaan dan deploy

Rules/indexes **belum dideploy** ke production. Review PR, hasil tes dan schema
sebelum operator deploy; tidak ada auto-merge. Katalog dan profil pegawai harus
disiapkan operator, tanpa seed palsu. UI manajemen katalog admin belum tersedia.

Persistensi native Auth/Firestore menggunakan SDK default, tetapi process-kill/
restart dan sync dua perangkat fisik belum diuji. Pengiriman email produksi juga
belum diuji. Emulator/fake bukan bukti native Android/iOS acceptance.

iOS harus dikonfigurasi melalui FlutterFire di Mac, memakai app/plist asli,
Xcode signing dan simulator/perangkat. Target iOS 15 existing dipertahankan;
tidak ada credential, Firebase app ID iOS atau signing palsu.

Slot masih satu booking per jam global, belum durasi lintas slot, kapasitas bay/
teknisi, hari libur atau reschedule. Kueri limit 50 kendaraan/layanan dan 100 booking,
belum pagination/agregat total. Keunikan plat belum dipaksakan. Pekerjaan teknisi,
Service Order, inventori, pembayaran dan laporan belum produksi.

Lihat [FIREBASE_SETUP.md](FIREBASE_SETUP.md) untuk Android/iOS, model data,
provisioning tepercaya, index, aturan transisi dan acceptance setelah deploy.
Commit final, hasil push dan URL PR dilaporkan pada respons penyelesaian;
lihat `git log -1` untuk commit yang memuat laporan ini. Berhenti pada Phase 02.
