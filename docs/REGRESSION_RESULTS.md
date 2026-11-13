# Hasil regresi audit 12-13 November 2026

Base `828fc59b656f43d93ddbc07901f27b57172dd011`, branch main, Windows.
Flutter 3.44.2/Dart 3.12.2. JBR Android Studio, Gradle cache existing.
Firebase test memakai `demo-bengkelku`, Auth 9099/Firestore 8080, tanpa produksi.
ADB kosong. Log lokal lengkap disimpan di
`D:/Portfolio-Projects/.bengkelku-tools/audit-20261112/`.

| Pemeriksaan | Expected | Actual / status |
| --- | --- | --- |
| Preflight Git | main sinkron, perubahan pengguna terlindungi | PASS; HEAD=origin/main; backup patch/file awal |
| flutter pub get | Dependency terpasang | PASS, lockfile tidak berubah |
| Baseline flutter test | Semua tes existing lulus | FAIL awal: 132 pass, 2 fail karena tap di luar viewport |
| Reproduksi QA-14/15/16 | Tes gagal pada penyebab yang diprediksi | PASS reproduksi: 3 failing assertions/exception, 2 kontrol positif pass, `red.log` |
| Retest terarah | Perbaikan menyelesaikan kasus tanpa menghapus assertion | PASS 8/8, `green-targeted-final.log` |
| npm run check:firebase | Konfigurasi dan indeks sesuai | PASS 35 definisi, bukan verifikasi READY production |
| npm run test:rules | Auth/Rules/integrasi tidak gagal | PASS 40/40, 0 skipped; seed/reset/realtime dan race, `rules.log` |
| flutter build apk --debug --no-pub | APK berhasil dibangun | PASS 304,9 detik, `apk.log`; warning KGP/native access existing |
| dart format . | Format seluruh proyek | BLOCKED traversal folder build lama dengan path tidak ditemukan; tidak menghapus artefak pengguna |
| dart format lib test | Format seluruh source Dart aplikasi/test | PASS, 97 file, 0 changed; `format-final.log` |
| flutter analyze --no-pub | Tidak ada issue | PASS, No issues found, 57,1 detik; `analyze-final.log`. Dua lint lokal awal diperbaiki |
| flutter test --no-pub final | Tidak ada regresi | PASS 142/142, 0 gagal, 1:49; `flutter-final.log` |
| Screenshot before/after | Raster fixture aktual | PASS kedua capture test, empat PNG diperiksa; keluhan utuh, submit disabled saat katalog kosong |
| git diff --check | Tidak ada whitespace error | PASS, hanya pemberitahuan konversi LF/CRLF Windows |
| Infinix AND-01..11 sesi ini | Perangkat tersedia | NOT RUN, `adb devices -l` tanpa perangkat |
| Native iOS | Build/smoke Xcode | NOT RUN, host Windows |
| Native PDF print/share | Dialog native dan hasil nyata | NOT RUN; PDF bytes diuji otomatis |
| UAT pengguna nyata | Responden dan hasil aktual | NOT RUN |
| CI baseline | Commit awal lolos workflow | PASS [42541887178](https://github.com/Freddy47588/Aplikasi-Bengkel/actions/runs/42541887178), source 828fc59 |

APK working tree berukuran 216.363.781 byte, SHA-256
`2e752bb5e5048559aa056c049ef0fc344d59cadecee316d379c0370c1af25432`.
Build debug ini bukan release signed atau hasil CI. Manifest 224 path (66 Dart
aplikasi dan 31 Dart test termasuk helper) serta hash log/PNG/APK ada pada
[evidence](evidence/full-audit-20261112/README.md). Hash source mencakup perubahan
lokal yang sengaja tidak dipush. Tanggal folder 20261112 adalah awal audit;
validasi akhir dan dokumentasi dilanjutkan 13 November Asia/Jakarta.

CI source audit **PASS** pada
[run 43353103019](https://github.com/Freddy47588/Aplikasi-Bengkel/actions/runs/43353103019),
commit `728deb4f04b49f1911e76202bdff76de78d740cf`, 13 November 2026.
Job Flutter: pub get PASS, format seluruh checkout `.` PASS (96 file, 0 changed),
analyze tanpa issue (16,8 detik), **140 tests passed**. Job Firebase:
check config PASS, **39 pass, 0 fail, 0 skipped** (25115 ms).
Runner Ubuntu, Flutter 3.44.2, Node 22 dan Temurin Java 21 sesuai workflow.
Build APK lokal tercatat terpisah karena workflow tidak membangun APK.
Commit dokumentasi sesudah source ini tidak mengubah kode aplikasi/test;
tautan workflow terbaru tersedia pada
[BengkelKu QA main](https://github.com/Freddy47588/Aplikasi-Bengkel/actions/workflows/qa.yml?query=branch%3Amain).

Commit perbaikan yang dipush normal ke main:

- `9faf9571cf6d60c80c48cad6562ba091dcba5e1e`: guard katalog dan review booking.
- `0eb6f4b68860161685a77c435013fcaeaa98df31`: batas durasi laporan.
- `728deb4f04b49f1911e76202bdff76de78d740cf`: regresi skala teks, capture dan tap ringkasan.

Remote dicek sebelum push; tidak ada divergence. Tidak ada branch/PR baru,
force push, production deploy atau perubahan file lokal pengguna dalam commit.
Scan diff terhadap pola private key/token tidak menemukan kredensial; log
emulator mentah, APK, data akun dan generated registrant tidak disertakan.

Pengujian lokal memakai working tree termasuk perubahan pengguna yang belum
dikomit. CI source audit hanya mencakup file audit yang dipublikasikan, sehingga
jumlah hasil adalah 142 Flutter/40 Firebase lokal dan 140 Flutter/39 Firebase CI.
Tidak menyebut hasil working tree sebagai hasil
persis commit remote. Tes baru menambah race katalog, single review, recovery
katalog, batas periode dan skala 150% lintas role. Cakupan 100/130/200% tetap
berasal dari suite existing; 150% menambah 105 kunjungan route (21 route x
5 lebar: 320/360/390/430/800dp), setiap route digulir lima kali dan diperiksa
exception. Ini uji layout/routing, bukan bukti submit semua fitur. Layar native
dan UAT tidak digantikan fixture.

QA Gate acceptance tetap BLOCKED untuk UAT, perangkat, iOS, QA-13 native dan
gap kebutuhan yang terdokumentasi. Perbaikan aman boleh dipublikasikan setelah
quality gate otomatis lulus. Tidak ada deploy Firebase/production.
