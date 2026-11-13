# Evidence audit 12-13 November 2026

Base `828fc59b656f43d93ddbc07901f27b57172dd011`, Windows,
Flutter 3.44.2/Dart 3.12.2, Firebase Emulator `demo-bengkelku`.
Source diuji sebagai working tree dengan perubahan pengguna sebelumnya yang
tetap tidak dipublikasikan. Jangan menyamakan hash working tree dengan commit
remote. Folder menggunakan tanggal mulai; penyelesaian 13 November WIB.

`working-tree-manifest.json` menginventarisasi 224 file dengan SHA-256, termasuk
66 Dart aplikasi dan 31 Dart test/helper. Inventaris bukan klaim setiap baris
diaudit manual atau seluruh jalur runtime diuji. `artifact-hashes.json`
merekam hash log lokal, APK debug dan PNG. Log lengkap berada di
`D:/Portfolio-Projects/.bengkelku-tools/audit-20261112/`; log emulator mentah
tidak dipublikasikan karena dapat memuat token/OOB pengujian.

## Reproduksi dan hasil

| ID | Langkah / expected | Actual sebelum | Actual setelah |
| --- | --- | --- | --- |
| QA-14 | Isi form; hapus layanan sebelum next frame; submit harus memberi feedback tanpa write | `Bad state: No element`, `firstWhere`, customer_booking_screen:45 | Tidak ada exception/dialog/write; input tetap ada |
| QA-15 | Panggil konfirmasi dua kali sebelum rebuild; satu review | `Expected: exactly one matching candidate`, `Found 2 widgets with type AlertDialog` | Satu dialog; cancel membuka form dan nol write |
| QA-16 | Query 31 hari + 1 detik; harus ditolak | Future selesai tanpa ArgumentError | ArgumentError; tepat 31 hari diterima |
| QA-17 | Reveal kontrol sebelum tap; assertion bisnis tetap | Baseline 132 pass, 2 fail akibat tap di luar viewport; analyze dua lint lokal | 142 pass, 0 fail; analyze bersih |

`red.log` mencatat 2 pass/3 fail (tiga reproduksi runtime).
`green-targeted-final.log` mencatat 8 pass, kemudian `flutter-final.log`
mencatat 142 pass dalam 1:49. `rules.log`: 40 pass, 0 fail, 0 skipped,
176828 ms. `analyze-final.log`: No issues found, 57,1 detik.
`format-final.log`: 97 files, 0 changed. `apk.log`: built debug APK,
304,9 detik. Rincian perintah dan batasan ada pada
[REGRESSION_RESULTS](../../REGRESSION_RESULTS.md).

CI source terpublikasi `728deb4` PASS pada
[43353103019](https://github.com/Freddy47588/Aplikasi-Bengkel/actions/runs/43353103019):
140 Flutter, 39 Firebase, 0 gagal. Format `.` 96 file tanpa perubahan dan analyze
tanpa issue. Perbedaan jumlah terhadap working tree bukan tes dihapus; file
pengguna yang sudah dirty/untracked tidak ikut commit audit.

## Screenshot fixture, bukan perangkat

Capture memakai 390x740dp, pixel ratio 2, skala 100%, Roboto SDK,
MaterialIcons SDK, FakeFirestore dan katalog layanan kosong. Before memakai
source booking base HEAD sementara; setelah capture source perbaikan
dikembalikan. After memakai source audit. Perintah:

```powershell
flutter test --no-pub --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/evidence/full-audit-20261112/after test/audit_booking_evidence_test.dart
```

| Bagian | Sebelum | Sesudah | Observasi |
| --- | --- | --- | --- |
| Katalog kosong | [before](before/fixture-booking-empty-top.png) | [after](after/fixture-booking-empty-top.png) | Petunjuk dan dropdown tetap terbaca, layout identik |
| Keluhan dan konfirmasi | [before](before/fixture-booking-empty-submit.png) | [after](after/fixture-booking-empty-submit.png) | Teks keluhan tetap utuh; CTA aktif menjadi disabled saat katalog kosong |

Kedua test capture PASS, empat PNG diperiksa langsung. Tidak ada screenshot
Infinix, hasil UAT, atau perbandingan langsung 10 mockup asli dalam sesi ini.
ADB kosong pada pemeriksaan ulang. Native Android/iOS, print/share, offline dan
UAT tetap NOT RUN. QA acceptance keseluruhan tetap BLOCKED.
