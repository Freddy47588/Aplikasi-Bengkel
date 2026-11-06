# Data pengujian Phase 07

Hanya Auth/Firestore Emulator `demo-bengkelku`. Data ini untuk development,
demonstrasi terisolasi dan QA, bukan pencapaian/omzet bengkel asli. Jangan salin
akun, transaksi atau export emulator ke `bengkelku-app-bebd9`.

## Menyiapkan dan menjalankan

Gunakan Node 22 (CI) atau 24, Java 21+, Flutter 3.44.2/Dart 3.12.2 dan dependency lockfile.
Di Windows gunakan `npm.cmd` bila kebijakan PowerShell memblokir `npm.ps1`.
Pastikan `java` dan Node versi tersebut ada di PATH terminal. Contoh JDK bawaan
Android Studio pada Windows:

```powershell
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:Path="$env:JAVA_HOME\bin;$env:Path"
java -version
node --version
```

Pada host sesi ini Node global 26 mengeluarkan engine warnings; pengujian memakai
Node 24.22.1 lokal. Jika environment global mengaktifkan DEBUG, kosongkan untuk
terminal QA (`$env:DEBUG=''`) agar output tooling tidak berlebihan.

```sh
npm ci --no-audit --no-fund
npm run check:firebase
npm run emulators:start
```

Terminal kedua, PowerShell:

```powershell
$env:GCLOUD_PROJECT='demo-bengkelku'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
npm.cmd run data:seed
npm.cmd run data:validate
```

POSIX: `export GCLOUD_PROJECT=demo-bengkelku`, lalu export kedua endpoint yang
sama. Seed/reset menolak project lain, host remote, protokol dalam host, port
tidak valid, variabel project yang bertentangan dan emulator yang mati. Kedua
API emulator diperiksa sebelum mutasi, request tidak mengikuti redirect.
Tidak menggunakan service account atau application default credentials.

## Akun

| UID | Email | Role |
| --- | --- | --- |
| p07-admin | admin.demo@bengkelku.test | admin |
| p07-customer | customer.demo@bengkelku.test | customer |
| p07-customer2 | customer2.demo@bengkelku.test | customer |
| p07-technician | technician.demo@bengkelku.test | technician |

Password acak lokal ditulis ke `.firebase/phase07-credentials.json`, diabaikan
Git dan tidak dicetak oleh script. File berisi password emulator saja. Jangan
bagikan atau gunakan password ini di project asli. Semua akun verified/active;
akun unverified/inactive diuji terpisah oleh suite existing. Admin/teknisi
diprovisikan melalui endpoint administrasi Auth Emulator dan trusted Firestore
test context, bukan register publik. Dokumen users tidak mendapat field tambahan.

## Login Flutter pada emulator

Pada main mulai 316b6ab, pemetaan host otomatis SDK dinonaktifkan dan build
Android debug mengizinkan HTTP hanya ke host lokal emulator. Rebuild APK jika
memakai versi sebelumnya. Pada Infinix USB, periksa `adb reverse --list` setelah
menyambungkan ulang kabel atau memulai sesi baru, kemudian validasi dataset.

```sh
flutter run --dart-define=USE_FIREBASE_EMULATOR=true --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

`10.0.2.2` hanya untuk Android Virtual Device. Untuk Infinix USB:
Pastikan `adb` tersedia di PATH atau gunakan executable dari `platform-tools`
pada Android SDK setempat.

```sh
adb reverse tcp:8080 tcp:8080
adb reverse tcp:9099 tcp:9099
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

Project Firebase pada mode ini selalu `demo-bengkelku`; host hanya localhost,
127.0.0.1 atau alamat host AVD. Mode ini menolak profile/release dan tidak
mengaktifkan cache Firestore persisten. Opsi port: `FIREBASE_AUTH_PORT` dan
`FIRESTORE_PORT`. Tanpa flag, konfigurasi Firebase existing digunakan.
Jangan mencampur sesi acceptance emulator dengan aplikasi production.
Pengujian UI/screenshot harus diberi keterangan DATA EMULATOR pada catatan bukti.

## Manifest dan konsistensi

Manifest ekspektasi yang dikomit: `test_data/phase07.manifest.json`, tanpa
password. Integrasi membandingkan akun, jumlah dokumen dan omzet fixture
terhadap manifest ini. Timestamp/path slot aktual disimpan pada manifest runtime.

`_testManifests/phase07` menyimpan daftar path/UID dan status building/complete,
dengan akses client default-deny. ID p07/P07 deterministik; slot memakai epoch
jam 09:00 WIB pada delapan hari berikutnya. Ini simulasi alur dipercepat: SO
diselesaikan seketika untuk menyiapkan contoh riwayat, bukan catatan jadwal
operasional nyata. Tidak ada createdBy tambahan pada schema yang melarangnya.

Seed provisioning profil memakai trusted emulator context. Seluruh operasi
kendaraan, katalog, booking/slot, direktori teknisi, SO/event, stok/request/usage,
invoice dan pembayaran menggunakan Firebase SDK dengan login Auth sebenarnya
dan melewati Rules repository. Satu teknisi mengerjakan empat SO berturut-turut
dan memegang satu SO aktif. Riwayat menggunakan SO completed, bukan koleksi baru.
Jasa disahkan per SO karena schema katalog tidak memiliki field harga.

| Koleksi/subkoleksi | Jumlah |
| --- | ---: |
| Auth / users | 4 / 4 |
| vehicles / services / technicians | 6 / 5 / 1 |
| bookings / bookingSlots | 8 / 8 |
| serviceOrders / events | 5 / 27 |
| spareparts / stockMovements | 12 / 17 |
| partRequests / partUsages | 5 / 5 |
| invoices / payments | 4 / 8 |
| _testManifests | 1 |

Booking: 5 confirmed, 1 pending, 1 cancelled, 1 rejected. SO: 4 completed dan
1 inProgress. Invoice: unpaid, partial, paid, refunded. Stok awal melalui 12
receipt, diikuti 5 usage melalui approval request. Satu SKU lowStock. Omzet
fixture paid Rp127.000; partial/unpaid/refunded dikecualikan. Nilai ini bukan
omzet production. Validator memeriksa relasi, slot, rantai saldo/revisi,
snapshot usage/harga jasa, audit dan aritmetika invoice/payment.

Seed ulang pada manifest complete hanya memvalidasi, tidak menimpa perubahan
tester. Jika seed terputus/building, reset dahulu. Script menolak benturan path
atau akun existing tanpa manifest. Jangan menjalankan dua seed/reset serentak.
Manifest menyebut path seed saja; transaksi manual tambahan perlu dihapus
dengan menghentikan emulator tanpa export dan memulai instance kosong.

## Test dan reset

Hentikan instance manual sebelum `npm run test:rules` agar port bebas. Perintah
ini menyalakan dan mematikan emulator sendiri, menjalankan seluruh test secara
serial (suite existing melakukan clearFirestore). Gunakan instance khusus QA,
karena suite Rules mereset database emulator; jangan arahkan ke instance kerja.

```sh
npm run test:rules
```

Pada instance manual dengan variabel environment di atas:

```sh
npm run data:reset
npm run data:reset
npm run data:seed
```

Reset menghapus path dan akun manifest saja, termasuk subkoleksi sebelum
menghapus manifest; aman diulang dan menangani akun yang belum tercipta saat
seed terputus. Password lokal ikut dihapus. Tidak ada endpoint penghapusan
seluruh database produksi. Sebelum demo berikutnya, validator harus PASS.

Referensi: [Firebase Auth Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth)
dan [konfigurasi Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure).
