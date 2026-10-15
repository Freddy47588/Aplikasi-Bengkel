# Firebase Setup — BengkelKu

## Phase 04: inventori

Lihat [PHASE_04_REPORT.md](PHASE_04_REPORT.md) untuk schema, invariant ledger,
approval teknisi, reversal, pengujian dan batas transaksi client-only. Deploy
rules dan indexes Phase 04 bersama-sama setelah review; tunggu indexes READY dan
smoke query semua kombinasi filter. Tidak ada backfill stok tersembunyi: master
baru selalu stok 0; stok awal harus dicatat sebagai receipt atau adjustment dengan
alasan. SKU canonical permanen; penghapusan memakai arsip. Tidak memakai Functions,
Storage atau Blaze. Native iOS dan production E2E tetap belum diverifikasi.

## Phase 03: teknisi dan Service Order

Schema/transisi, index tambahan dan acceptance Phase 03 dijelaskan di
[PHASE_03_REPORT.md](PHASE_03_REPORT.md). Deploy rules dan indexes bersama-sama
setelah review. Aplikasi tetap Firebase Spark Auth + Firestore, tanpa Functions
atau Storage. Instruksi dan batas Phase 02 di bawah adalah catatan sebelumnya.

## Phase 02

Audit: 15 Oktober 2026 (Asia/Jakarta). Base `9413c42` di fork
`Freddy47588/Aplikasi-Bengkel`, setelah Phase 01 merged melalui PR #2.

## Project asli dan batas biaya

- Project: `bengkelku-app-bebd9`, nomor `932140419370`.
- Android app: `1:932140419370:android:f69ab7bc5097462078b653`.
- Package Android dan bundle ID iOS: `id.bengkelku.mobile`.
- Firestore `(default)`: Native/Standard, `asia-southeast2`, `freeTier: true`.
- Pemeriksaan read-only API project: Email/Password aktif; `billingEnabled: false`.
- Hanya Firebase Authentication Email/Password dan Cloud Firestore. Tidak ada
  Storage, Functions, SMS OTP, payment gateway, atau perubahan billing/Blaze.
- Spark mempunyai kuota, termasuk pengiriman email dan operasi Firestore.
  Batasi percobaan manual; tinjau penggunaan di console. Kuota habis dapat membuat
  permintaan gagal; aplikasi tidak mengaktifkan billing otomatis.

Konfigurasi client FlutterFire (`firebase_options.dart`, `google-services.json`)
bukan service-account key. Otorisasi data tetap bergantung pada rules. Jangan
memasukkan token CLI, refresh token, private key, signing key, atau password akun
ke repo. File kosong lokal `1.3` dan `customer` bukan source aplikasi.

## Android

Konfigurasi dijalankan dengan project dan app asli, bukan placeholder:

```sh
flutterfire configure --project=bengkelku-app-bebd9 --platforms=android --android-package-name=id.bengkelku.mobile --yes
flutter pub get
flutter run -d <android-device>
```

Plugin Google Services ada di Gradle dan permission INTERNET di manifest utama.
Kotlin incremental compilation dinonaktifkan di `android/gradle.properties` karena
build Windows gagal merelatifkan source plugin di pub cache C: terhadap repo D:.
Konsekuensinya kompilasi Kotlin dapat lebih lambat. Setting dapat dievaluasi ulang
setelah cache dan workspace berada pada volume yang sama; lihat
[dokumentasi Kotlin](https://kotlinlang.org/docs/gradle-compilation-and-caches.html).

`main()` menunggu Firebase sebelum memasang ProviderScope; kegagalan konfigurasi
menampilkan layar retry, tanpa fallback ke login demo. Target selain Android
menampilkan pesan konfigurasi jika belum dikonfigurasi.

Firebase Auth menyimpan sesi secara native. Firestore native menyimpan cache;
server menjadi sumber data lintas perangkat. Transaksi booking memerlukan jaringan
dan gagal saat offline; jangan menganggap cache sebagai konfirmasi slot.

## iOS — wajib dituntaskan di Mac/Xcode

Konfigurasi iOS belum dibuat dan build native iOS **NOT VERIFIED** pada host
Windows ini. Tidak ada App ID Firebase, plist, Team ID atau signing iOS palsu.

1. Gunakan Mac dengan Flutter, Xcode dan CocoaPods yang kompatibel.
2. Jalankan dari repo:

   ```sh
   flutterfire configure --project=bengkelku-app-bebd9 --platforms=android,ios --android-package-name=id.bengkelku.mobile --ios-bundle-id=id.bengkelku.mobile
   flutter pub get
   cd ios
   pod install
   ```

3. Pastikan app iOS project benar, file `Google-Service-Info.plist` terpasang pada
   target Runner, dan opsi iOS di `firebase_options.dart` dihasilkan CLI.
4. Buka `ios/Runner.xcworkspace`; bundle ID `id.bengkelku.mobile`, target iOS 15.0
   existing. Pilih Development Team asli untuk perangkat.
5. Build simulator, kemudian uji register/login/verifikasi/reset password,
   CRUD kendaraan, submit/status/cancel booking dan restart pada iPhone.
6. Review perubahan konfigurasi yang dihasilkan sebelum commit.

## Identitas, verifikasi dan provisioning tepercaya

Registrasi publik hanya membuat `users/{uid}` dengan `email`,
`role: customer`, `active: true`, `createdAt` server timestamp. Profile creation
idempotent: gagal jaringan dapat dicoba melalui **Lengkapi profil pelanggan**.
Login tidak menimpa role/active akun existing. Kata sandi tidak disimpan di Firestore.

Email harus diverifikasi sebelum mengakses data operasional. Buka tautan email,
kembali ke aplikasi dan tekan **Periksa ulang status akun**. Aplikasi me-reload
user dan memperbarui ID token. Ada resend verification dan forgot password dengan
pesan netral. Profil yang dinonaktifkan mengarah ke Status Akun; rules menolak
akses walaupun UI atau token client dimanipulasi.

Provisioning Admin/Teknisi hanya oleh operator yang mempunyai akses IAM tepercaya
ke Firebase Console (atau Admin SDK di lingkungan operator, bukan aplikasi):

1. Buat akun Email/Password di Authentication Console untuk pegawai yang berhak;
   gunakan password asli yang disampaikan melalui proses internal yang aman.
2. Verifikasi alamat email pegawai. Aplikasi tetap memerlukan `email_verified`.
3. Buat `users/{uid}` dengan email sesuai Auth, `role: admin` atau `technician`,
   `active: true`, `createdAt` bertipe timestamp. Atau ubah profil customer
   existing melalui Console setelah identitas/otorisasinya ditinjau.
4. Login melalui form email yang sama. Tidak ada tombol pilih role.
5. Untuk menonaktifkan akses, set `users/{uid}.active = false` melalui Console,
   lalu disable user di Authentication. Profil active menjadi kontrol rules yang
   berlaku pada evaluasi permintaan berikutnya; disable Auth saja dapat menyisakan
   ID token sampai kedaluwarsa. Aplikasi refresh Auth saat kembali foreground.

Client, termasuk client Admin, tidak boleh mengubah role/active profil. Rules
menolak seluruh update/delete/list users. Teknisi hanya melihat halaman pekerjaan
demo; tidak mendapat akses koleksi booking pelanggan pada Phase 02.

## Model data dan kueri

| Path | Isi dan akses |
| --- | --- |
| `users/{uid}` | Email, role, active, createdAt. Get profil sendiri; create customer sendiri; perubahan hanya operator tepercaya |
| `vehicles/{id}` | ownerId, name, plate, active, createdAt, updatedAt. CRUD pemilik; hapus berupa archive active=false |
| `services/{id}` | name, active, createdAt, updatedAt. Customer read layanan aktif; admin write |
| `bookings/{id}` | customerId, vehicleId/name/plate, serviceId/name, scheduledAt, complaint, status, slotId, createdAt, updatedAt. Snapshot immutable; customer sendiri atau admin |
| `bookingSlots/{epochMillis}` | bookingId, scheduledAt, active. Shared lock tanpa identitas/keluhan; get akun terverifikasi aktif, list/delete ditolak |

Vehicle name 1–80 karakter dan plat Indonesia umum `B 1234 XYZ` dinormalisasi
uppercase. Kepemilikan immutable. Plat khusus, korps/diplomatik dan plat luar
negeri belum didukung; keunikan plat lintas dokumen belum dipaksakan.
Booking menyimpan snapshot kendaraan/layanan dari dokumen server, sehingga edit
atau archive kendaraan tidak mengubah riwayat booking.

Semua kueri melalui repository/Riverpod. Vehicles: filter ownerId+active, limit 50;
services: active, limit 50; bookings customer: customerId + createdAt desc, limit
100; admin: createdAt desc, limit 100. Indeks tersimpan di
`firestore.indexes.json`; complaint tidak diindeks. Angka dashboard adalah jumlah
dari hasil terbatas itu, bukan agregat seluruh database. Pagination belum tersedia.

Operator mengisi katalog melalui Firestore Console, contoh dokumen `services/oil`:
`name: Ganti Oli`, `active: true`, `createdAt` dan `updatedAt` timestamp.
Tidak ada seed demo otomatis ke project asli. Katalog kosong ditampilkan sebagai
kosong; UI manajemen katalog admin belum termasuk fase ini, tetapi admin writes
melalui client yang sesuai schema dilindungi dan diuji rules.

## Slot, transaksi dan transisi

- Waktu bengkel selalu Asia/Jakarta (UTC+7), disimpan Timestamp UTC. UI menampilkan WIB.
- Jam mulai 09, 10, 11, 13, 14, 15, 16; masa depan sampai 90 hari; keluhan 5–500 karakter.
- Kapasitas konservatif **satu booking per jam untuk seluruh bengkel**, termasuk
  pending. Belum ada kapasitas per bay/teknisi, durasi lintas jam, kalender libur,
  reschedule atau waitlist. Jangan menganggap booking satu jam menjamin durasi servis.
- Slot ID canonical = scheduledAt epoch milliseconds. Transaksi membaca lock,
  kendaraan dan layanan sebelum menulis booking+lock. Dua transaksi bersaing
  hanya dapat menghasilkan satu booking; SDK mengulang transaksi yang konflik.
- Rules `getAfter()` mewajibkan pasangan booking/lock konsisten. Membuat booking
  tanpa lock, memakai slot ID lain, merebut lock, atau release lock sendiri ditolak.
- Admin: pending → confirmed/rejected. Customer pemilik: pending/confirmed →
  cancelled. Rejected/cancelled terminal. Confirm mempertahankan lock; reject/cancel
  melepaskan lock atomik. Slot yang inactive dapat dipakai booking baru.
- Admin tidak mengubah owner, kendaraan, layanan, jadwal, snapshot atau complaint.
  Delete booking ditolak. Data tersinkron dari stream Firestore, bukan list demo.

## Pengujian dan review deploy

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
npm ci --no-audit --no-fund
npm run test:rules
```

Node dan Java yang kompatibel Firebase CLI diperlukan. Script emulator memakai
project lokal `demo-bengkelku`, Auth 9099 dan Firestore 8080; tidak mengirim email
atau data test ke Firebase asli. Hindari DEBUG=* saat menjalankan CLI karena
debug log dapat mencetak environment lokal. Log/cache emulator diabaikan Git.

Rules tests menguji owner isolation, self-promotion, unknown fields, immutable
ownership, layanan admin, akun nonaktif/tidak terverifikasi, transisi ilegal,
lock atomik, dua transaksi concurrent dan pembacaan dari client baru. Auth Emulator
menguji register → verification OOB lokal → login client baru → data tersimpan →
forgot/reset password. Ini belum membuktikan pengiriman email produksi maupun
persistensi cache/session native Android/iOS setelah process kill.

**Rules dan indeks belum dideploy ke production.** Review PR dan hasil tes dahulu.
Setelah review, operator dapat menjalankan perintah berikut secara manual:

```sh
firebase deploy --only firestore:rules,firestore:indexes --project bengkelku-app-bebd9
```

Perintah di atas adalah prosedur operator, bukan aksi yang dilakukan oleh fase ini.
Sebelum review/deploy, jangan mengandalkan rules production existing. Setelah
deploy dan katalog/profil pegawai siap, uji acceptance dengan dua akun asli di dua
perangkat: register/verify, CRUD kendaraan, booking bentrok, admin confirm/reject,
customer cancel, restart, logout/login dan isolasi akun.

Tidak ada perangkat Android terhubung pada pre-flight; uji dua perangkat belum
dijalankan. iOS tetap memerlukan Mac/Xcode. Hasil validasi lokal final dicatat di
`docs/PHASE_02_REPORT.md`. Scope berhenti pada Phase 02.

Referensi resmi: [Auth Email/Password](https://firebase.google.com/docs/auth/flutter/password-auth),
[Auth Flutter](https://firebase.google.com/docs/auth/flutter/start),
[transaksi Firestore](https://firebase.google.com/docs/firestore/manage-data/transactions),
[rules dan getAfter](https://firebase.google.com/docs/firestore/security/rules-conditions).


## Phase 05 - riwayat dan tracking

Riwayat adalah query `serviceOrders` dengan `status == completed`, bukan koleksi
input manual `serviceHistories`. Single-bengkel per Firebase project; admin aktif
proyek hanya mengelola bengkel ini. Multi-bengkel memerlukan tenant ID + rules
terpisah, belum diimplementasikan. Customer query wajib `customerId == uid`,
teknisi wajib `technicianId == uid`; admin boleh semua SO bengkel proyek.

SO menambahkan `laborPrice` (null sebelum admin mencatat integer rupiah 0-1 miliar)
dan `technicianName` (snapshot nama saat assignment; fallback saat completion untuk
SO lama). Perubahan biaya hanya admin, revision + event `pricingUpdated` atomik.
Completion wajib harga jasa tercatat, server `completedAt`, event dan pelepasan
lock teknisi dalam transaksi yang sama. SO terminal tidak bisa diedit/dihapus.
Rules Phase 05 juga menolak pemakaian **dan reversal usage** setelah terminal,
termasuk batch yang mencoba menyelesaikan SO sekaligus menambah usage/reversal.
Reversal penerimaan/koreksi stok tanpa SO tetap memakai aturan ledger Phase 04.

Harga sparepart dibaca dari `partUsages.sellPrice`, nama/satuan/qty snapshot;
reversal mengurangi biaya dengan harga original. Tidak membaca harga master atau
harga beli. Detail memuat seluruh halaman immutable (maksimal 20 per request)
sebelum menampilkan total. Biaya jasa lama yang tidak ada tetap ditandai tidak
tercatat; jangan mengisi balik harga master saat ini. Status pembayaran "Belum
dicatat" sampai modul Phase 06, bukan klaim sudah/belum lunas.

Query riwayat: status + scope role + vehicleId/serviceId opsional, rentang
completedAt `[awal WIB, hari sesudah akhir WIB)`, completedAt descending dan
ID ascending. Dua belas composite indexes mencakup tiga scope x empat kombinasi
filter; rentang tanggal menggunakan order yang sama. List maksimal 20, cursor
startAfterDocument. Halaman penuh bisa menawarkan halaman kosong berikutnya.
Cache ditandai mungkin belum lengkap; pagination maju dan total penuh ditahan
saat cache. Listener reconnect memperbarui daftar. Detail immutable dibaca on
open/retry; tidak ada listener semua stok atau duplikasi snapshot history.

Pemetaan: booking pending -> pending, confirmed tanpa SO / SO queued -> confirmed,
SO assigned -> assigned, inProgress/paused/awaitingApproval -> inProgress,
SO completed -> completed. Rejected/cancelled berhenti eksplisit. Booking tetap
confirmed selama servis; status SO menjadi sumber progres setelah SO dibuat.
Timeline menunjukkan tahap status kini, bukan log seluruh pause/resume/rework;
log revisi tetap berada di subkoleksi events yang immutable.

Deploy production belum dilakukan. Review dan deploy rules/indexes bersama sebelum
memakai client Phase 05, tunggu indexes ready, lalu acceptance dua akun/perangkat.
Tidak menggunakan Storage, Functions, billing upgrade, export atau upload dokumen.
Lihat [laporan Phase 05](PHASE_05_REPORT.md). STOP PHASE 05.


## Phase 06: pembayaran manual

Schema invoice/payment, role kasir sebagai admin, transisi, indexes, estimasi reads,
PDF lokal dan batas verifikasi: [PAYMENT_SCHEMA.md](PAYMENT_SCHEMA.md).
Review/deploy rules dan indexes bersama setelah review PR, tunggu READY.
Tidak ada deploy production atau billing upgrade pada Phase 06.
