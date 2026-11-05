# Phase 07: QA, data emulator, keamanan dan acceptance

5 November 2026, Asia/Jakarta. Repository Freddy47588/Aplikasi-Bengkel, hanya
branch `main`. HEAD awal `c63b54903217b5f1338934cb022075d7f1ecfa0e`.
HEAD commit akhir dilaporkan pada hasil Git sesi; hash commit tidak ditanam
ke dalam commit itu sendiri.

## Scope dan pre-flight

Fetch origin berhasil; HEAD awal sama dengan origin/main (0 ahead/0 behind).
Tidak ada AGENTS.md berlaku. Laporan Phase 02–06, 06.5, status terbaru,
FIREBASE_SETUP dan PAYMENT_SCHEMA dibaca; seluruh file test existing diaudit.
Perubahan lokal awal pada registrant Linux/macOS/Windows dipertahankan dan
tidak dimasukkan ke commit QA. Tidak membuat branch, worktree atau PR; tanpa
reset, force push, Firebase deploy atau upgrade billing.

Seluruh 18 file test Flutter existing dan 5 suite test_rules existing
dipertahankan. Tidak mengubah Rules atau struktur test lama. Tambahan: guard
Flutter emulator, dua guard seed/reset, dan satu integrasi lintas modul dengan
login Auth Emulator sebenarnya. Perubahan aplikasi terbatas pada pemilihan
Firebase app/environment dan provider, tanpa redesign UI/UX.

## Hasil pemeriksaan aktual

| Pemeriksaan | Status sesi |
| --- | --- |
| flutter pub get | PASS, dependency existing; lockfile tidak diubah |
| npm ci --no-audit --no-fund | PASS, 691 package, 18 menit; Node host 26 mengeluarkan engine/deprecation/install-script warnings |
| dart format --output=none --set-exit-if-changed . | PASS, 79 file, 0 perubahan |
| flutter analyze final | PASS, No issues found; run terakhir setelah API demoProjectId, 766,2 detik |
| flutter test final | PASS, 102 test, 0 gagal; 101 existing + 1 guard emulator |
| flutter build apk --debug final | PASS, rebuild source terakhir 280,7 detik |
| node tools/check-firebase-config.cjs | PASS, 35 definisi index, query wajib dan konfigurasi aman |
| Guard endpoint/project dan emulator mati | PASS, 2 test, 0 gagal pada Node 24.22.1 |
| npm run test:rules final | PASS, 38 test, 0 gagal, 130,2 detik (35 existing + 2 guard + 1 integrasi) |
| Seed/reset/rekonsiliasi/integrasi | PASS, integrasi pada suite final 25,5 detik; targeted 67,1 detik; 8 pemanggilan CLI seed/validate/reset PASS |
| git diff --check | PASS pada pemeriksaan saat penulisan; diperiksa lagi sebelum commit |
| Review credential | PASS, 26 file QA staged; tidak ada pola private key/token, artefak lokal atau registrant pengguna |

Run sebelum interupsi tidak dihitung sebagai PASS jika tidak memiliki hasil
selesai. Analisis dan build awal pernah berhasil, tetapi pemeriksaan final
diulang setelah perbaikan Firebase app bernama. Log lokal phase07-*.log,
APK, cache dan password tidak dikomit. Tooling lokal memakai Java 25.0.4/JBR,
Gradle/SDK cache existing dan fallback TCP JVM untuk Windows. CI memakai
Node 22 dan Java 21. Tidak mengubah toolchain production.

Run emulator pertama menyelesaikan seluruh 35 test existing dan 2 guard, tetapi
integrasi baru gagal pada timeout preflight 10 detik sebelum seed menulis data.
Probe laporan ruleCoverage diganti pembacaan manifest kecil/bounded dengan token
owner emulator-only; timeout menjadi 30 detik dan error mencantumkan lokasi.
Retest berikutnya menemukan helper yang tidak meneruskan nilai callback
withSecurityRulesDisabled (Promise<void>), lalu diperbaiki dengan capture nilai
eksplisit. Integrasi targeted, delapan pemanggilan CLI, dan seluruh 38 test
pada suite final sesudah kedua perbaikan PASS. Kedua bug script ditutup pada
QA-08/09; perubahan Rules tidak diperlukan.

APK final `build/app/outputs/flutter-apk/app-debug.apk`: 216.241.332 byte,
SHA256 `1C286F69B9AC670D9682994688891A93C7C23EC4E343C5ACC135708D25F0D6AE`.
Ini debug build dengan konfigurasi default existing, bukan bukti login perangkat.
Untuk login akun fixture, gunakan flag emulator pada TEST_DATA_GUIDE. SDK aktual
Flutter 3.44.2 stable, Dart 3.12.2. Ringkasan terstruktur tanpa password:
[PHASE_07_EVIDENCE.json](PHASE_07_EVIDENCE.json).

## Data dan akun

Project fixture selalu `demo-bengkelku`, Auth/Firestore endpoint loopback yang
divalidasi sebelum mutasi. Endpoint yang mati/remote, project non-demo,
variabel project bertentangan dan redirect ditolak. Tidak memakai service
account, token CLI atau credential production untuk provisioning.

| Akun | Role |
| --- | --- |
| admin.demo@bengkelku.test | admin |
| customer.demo@bengkelku.test | customer |
| customer2.demo@bengkelku.test | customer |
| technician.demo@bengkelku.test | technician |

Password dihasilkan acak, disimpan lokal di `.firebase/phase07-credentials.json`
(ignored), tidak dicetak/dikomit. Semua akun verified/active untuk demo normal;
skenario unverified, inactive dan Auth disabled diuji terpisah. Admin/teknisi
diprovisikan trusted hanya di emulator; tidak tersedia promosi publik/client.

Jumlah fixture aktual tervalidasi: users 4; vehicles 6; services 5; technicians 1; bookings 8;
bookingSlots 8; serviceOrders 5; events 27; spareparts 12; stockMovements 17;
partRequests 5; partUsages 5; invoices 4; payments 8; manifest 1.
Validator memeriksa 115 dokumen domain/subkoleksi dan satu manifest runtime.
Reset CLI menghapus 115 dokumen domain/subkoleksi, manifest dan empat akun Auth.
Riwayat bersumber dari empat SO completed, bukan koleksi duplikat.
Manifest ekspektasi tanpa password: `test_data/phase07.manifest.json`.

Semua mutasi domain seed melalui SDK client login nyata dan Rules: kendaraan,
katalog, booking+slot, SO+event, assignment+lock, checklist/diagnosis/tindakan,
request+usage+stok, completion, invoice+audit, partial/paid/refund. Satu teknisi
mengerjakan empat SO berurutan lalu memegang satu SO inProgress. Invoice
unpaid/partial/paid/refunded dan satu lowStock disediakan. Fixture adalah simulasi
waktu dipercepat, bukan transaksi nyata. Validator membandingkan referensi,
slot, saldo/revisi stok, audit dan snapshot/total/saldo pembayaran.

Seed ulang hanya memvalidasi manifest complete. Seed building atau benturan
data ditolak dan perlu reset. Reset menghapus path/subkoleksi/UID manifest,
menangani akun yang belum tercipta saat seed terputus, lalu menghapus manifest
dan password. Tidak menghapus database cloud. Cara start/login/test/reset:
[TEST_DATA_GUIDE.md](TEST_DATA_GUIDE.md).

## Keamanan, transaksi dan integrasi

Seluruh risiko yang diminta dipetakan di [SECURITY_AUDIT.md](SECURITY_AUDIT.md).
Suite existing mencakup register customer-only, eskalasi role/active, anonymous,
unverified/inactive, customer isolation, ownership/snapshot forged, query bounds,
assignment teknisi/race, stok negatif/tanpa witness/harga palsu, reversal,
terminal SO immutable, payment tampering/double-submit/overpay, audit immutable.
Integrasi tambahan menggunakan akun Auth sebenarnya, bukan hanya claims mock,
serta menguji Auth disabled, riwayat, paid-only revenue, realtime status,
seed berulang, reset berulang dan seed kembali.

Auth **PASS**: register, verifikasi, logout/login client baru, kendaraan persisten,
reset password dan penolakan login Auth disabled. Firestore Rules **PASS**: 38
test keseluruhan termasuk guard/integrasi. Transaksi **PASS**: alur normal,
tampering/akses lintas role, idempotensi, booking/assignment/stock/payment race,
reversal, audit immutable dan status terminal. Tidak ada bug kritis terbuka yang
teridentifikasi dalam cakupan otomatis ini; gap acceptance tetap terpisah.

Integrasi Node adalah integrasi backend dengan SDK Auth/Firestore; bukan driver
UI Flutter end-to-end. Widget/repository tests memakai fake/mock existing.
Klaim keamanan dibatasi hasil suite dan scope source; IAM/Console/billing asli
tidak diperiksa ulang. Admin tetap dipercaya saat mengesahkan subtotal/parts
invoice awal; Rules tidak fold ledger dinamis. Batas existing ini dipertahankan
dan membutuhkan rekonsiliasi operator, bukan dibuka untuk role lain.

## Matriks kemampuan Admin

C=create, R=read, U=update; arsip/koreksi mengikuti invariant. Tidak ada hak baru
yang diberikan demi istilah CRUD. Tabel berasal dari audit repository/UI/Rules.

| Modul | C | R | U | Delete / archive / koreksi |
| --- | --- | --- | --- | --- |
| Katalog services | Rules mengizinkan | Aktif/nonaktif, bounded 50 | Nama/active via Rules | Archive; UI CRUD belum tersedia (QA-01) |
| Booking | Customer pemilik | Admin semua, bounded 100 | Pending → confirm/reject | Tidak delete; reject melepas slot atomik |
| Teknisi | Direktori untuk UID trusted | Admin bounded 20 | Nama/spesialisasi/available/active | Archive saat lock bebas; tidak delete |
| Role/active users | Operator trusted | Admin hanya profil teknisi tertentu | Operator trusted saja | Tidak tersedia CRUD akun dari Flutter |
| Kendaraan | Customer pemilik | Customer pemilik | Customer pemilik | Archive oleh pemilik; admin membaca snapshot booking/SO |
| SO | Dari booking confirmed, ID canonical | Admin semua, bounded 20 | Assign/reassign/pricing/review/cancel | Tidak delete; terminal immutable |
| Sparepart master | Stok awal 0, SKU canonical | Admin-only bounded 20 | Metadata/harga/minimum, versioned | Archive, SKU historis tidak dipakai ulang |
| Stock movement | Receipt/adjustment/usage/reversal atomik | Admin-only bounded 20 | Immutable | Reversal penuh satu kali; tidak delete |
| Part request | Teknisi tugas sendiri | Admin / assigned technician | Admin approve/reject pending | Tidak delete; approve wajib movement+usage |
| Part usage | Admin melalui ledger atomik | Sesuai ownership SO | Immutable | Reversal saat SO nonterminal; tidak delete |
| Invoice | SO completed + snapshot + issued audit | Admin / customer pemilik | Payment, void/refund sesuai status | Void unpaid/refund penuh; tidak delete |
| Payment/audit | Admin atomik bersama invoice | Admin / customer pemilik | Immutable | Event koreksi terminal; tidak update/delete event lama |
| Laporan/dashboard | Hasil query, bukan dokumen report | Admin, periode maksimal 31 hari | Muat ulang | Tidak ada CRUD koleksi reports |
| PDF | Generate lokal dari snapshot | Admin/customer sesuai invoice | Generate ulang | Tidak upload Storage atau menulis Firebase |

Tidak ditemukan alasan untuk membuka Rules. Gap kebutuhan TA vs implementasi:
UI katalog belum tersedia; role management client sengaja dilarang; transaksi
immutable tidak boleh dihapus fisik. Lihat [BUG_TRACKER.md](BUG_TRACKER.md).

## Black-box, perangkat dan UAT

37 kasus UI disiapkan: 36 NOT RUN dan 1 BLOCKED (UI CRUD katalog tidak ada).
Actual tidak diisi dari unit test atau screenshot fixture. Rincian langkah,
input, expected, status dan bukti: [BLACK_BOX_RESULTS.md](BLACK_BOX_RESULTS.md).

ADB tidak mendeteksi perangkat terhubung saat audit: seluruh smoke Infinix
AND-01..11 **NOT RUN**. Build APK bukan bukti login/perilaku perangkat nyata.
Native PDF print/share, lifecycle, keyboard, jaringan putus, font, crash/overflow
perlu uji pada HP asli. iOS **NOT RUN** pada Windows tanpa Mac/Xcode/perangkat
dan konfigurasi Firebase iOS nyata. Rencana: [TEST_PLAN.md](TEST_PLAN.md).

UAT **NOT RUN**: tidak ada responden atau hasil penerimaan yang dikarang.
Tersedia instruksi tiga role, tugas, form bug/komentar, ringkasan penerimaan,
persetujuan opsional dan Likert 1–5. Template terpisah dari hasil aktual:
[UAT_TEST_PLAN.md](UAT_TEST_PLAN.md), [UAT_QUESTIONNAIRE.md](UAT_QUESTIONNAIRE.md).

## CI, production, Git dan gate

Workflow `.github/workflows/qa.yml` menjalankan pub get, format, analyze,
Flutter test, npm ci, check konfigurasi/indexes dan Auth/Firestore Rules test.
Trigger main push/PR, izin contents read, tanpa secrets atau deploy production.
Status remote workflow harus diperiksa terhadap commit yang benar sesudah push;
hasil lokal bukan klaim CI remote PASS.

Rules/indexes production: **NOT DEPLOYED**. Perintah operator dan checklist
READY/smoke query tercantum di SECURITY_AUDIT. Billing tetap tidak diubah dan
tidak menambah layanan di luar Auth/Firestore Spark existing.

Perubahan QA direview dan dipublikasikan melalui commit pada main saja; hasil
SHA/push dan CI remote diverifikasi sesudah commit. Registrant lokal awal tetap
di working tree dan dikecualikan dari commit. Tidak memakai force push.

Keputusan acceptance: **BLOCKED**, belum FULL PASS. Sebelum Phase 08: uji Infinix,
jalankan UAT nyata dan retest temuan; sepakati
gap katalog TA, periksa CI remote dan checklist operator deployment. Lihat
[QA_GATE.md](QA_GATE.md). Phase 08 tidak dimulai otomatis.
