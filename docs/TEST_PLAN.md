# Test plan Phase 07

Pelaksanaan lanjutan 6 November pada Infinix X6833B dicatat per AND-01..11
di [PHASE_07_DEVICE_RESULTS.md](PHASE_07_DEVICE_RESULTS.md). Hasil perangkat
pada bagian sesi 5 November di bawah dipertahankan sebagai riwayat.

Baseline main c63b54903217b5f1338934cb022075d7f1ecfa0e, 5 November 2026 WIB.
Tujuan: menguji Auth, otorisasi tiga role, transaksi atomik dan kesiapan
acceptance tanpa menulis data pengujian ke Firebase asli. Tidak ada redesign.

## Lapisan dan bukti

| Lapisan | Alat / cakupan | Bukti |
| --- | --- | --- |
| Unit/repository/widget | Seluruh test Dart existing + guard emulator | Log flutter test lokal; laporan Phase 07 |
| Auth | SDK register/verify/login/logout/reset pada Auth Emulator | test_rules/auth.test.cjs |
| Rules/negatif/race | Seluruh 5 suite existing dipertahankan | test_rules/*.test.cjs |
| Integrasi lintas modul | Auth login → kendaraan → booking/slot → confirm → SO → assign → checklist → request → usage → complete → history → invoice → pay → report | phase07_integration.test.cjs + tools/test-data.cjs |
| Guard seed/reset | Project/host/port/endpoint mati, tanpa cloud fallback | emulator_safety.test.cjs |
| Konfigurasi | Format, duplikasi, query indexes wajib, emulator localhost, CI tanpa deploy | tools/check-firebase-config.cjs |
| Black-box UI/native | Langkah aktual per role | BLACK_BOX_RESULTS.md; yang belum dijalankan NOT RUN |
| UAT nyata | Calon pengguna/pemilik/dosen sesuai peran | UAT_TEST_PLAN.md dan UAT_QUESTIONNAIRE.md, belum dilaksanakan |

Integrasi Node memakai SDK Auth/Firestore nyata dan Rules yang sama. Ini bukti
integrasi backend, bukan driver UI Flutter end-to-end. Test Dart existing memakai
fake/mock untuk repository/widget; keduanya saling melengkapi. Composite indexes
tidak dipaksakan Firestore Emulator; check statis bukan bukti index READY.

## Eksekusi

1. Fetch/status main; pertahankan perubahan lokal; baca laporan fase sebelumnya.
2. `flutter pub get`; `npm ci --no-audit --no-fund`.
3. `dart format --output=none --set-exit-if-changed .`.
4. `flutter analyze`; `flutter test`; `flutter build apk --debug`.
5. `npm run check:firebase`; `npm run test:rules`.
6. Seed dua kali, validasi, reset dua kali, seed/validasi kembali di emulator.
   Integrasi mengotomatisasi langkah ini serta menolak akses lintas role.
7. `git diff --check`, review credential dan diff; commit/push main jika tidak
   ada regresi kritis yang terbukti. Periksa hasil workflow remote terpisah.
8. Operator menjalankan black-box perangkat dan UAT, melampirkan bukti aktual.

## Android Infinix (manual)

Catat model, Android/API, RAM, ukuran layar, font, app commit/build SHA, koneksi,
jam WIB, penguji dan nomor bukti. Pakai instance emulator terisolasi, adb reverse,
akun pada TEST_DATA_GUIDE. Hapus log sensitif sebelum dibagikan.

| ID | Langkah | Harapan |
| --- | --- | --- |
| AND-01 | force-stop lalu cold start 3 kali | Splash selesai, login tampil, tidak crash/ANR |
| AND-02 | Login/logout bergantian customer/admin/teknisi | Route/data role tepat, sesi lama tidak tertinggal |
| AND-03 | Customer kendaraan/booking/cancel | Validasi, slot, status dan daftar realtime benar |
| AND-04 | Admin confirm/SO/assign; teknisi checklist/diagnosis | Transisi sesuai role, tidak ada overflow |
| AND-05 | Teknisi request; admin approve dan ledger | Satu decrement dan snapshot; retry tidak ganda |
| AND-06 | Complete/invoice/partial/paid/transfer | Total/sisa/kembalian benar; event tersimpan |
| AND-07 | Buka PDF, native print preview/share/cancel | Isi snapshot benar; plugin tidak crash |
| AND-08 | Background/foreground, process-kill, login ulang | Sesi/role direvalidasi, tidak mengirim ulang transaksi |
| AND-09 | Keyboard terbuka, Back, rotasi, font 1.0/1.3/terbesar | Input/tombol dapat dijangkau, tidak overflow |
| AND-10 | Putus koneksi sebelum/saat submit, hubungkan lagi | Error/retry jelas; audit diperiksa sebelum transaksi baru |
| AND-11 | Review logcat crash dan Flutter rendering errors | Tidak ada fatal exception/RenderFlex overflow |

Sediakan bukti berupa rekaman/screenshot asli berlabel data emulator, log yang
sudah disanitasi dan actual result per baris. Tidak memakai fixture screenshot
sebagai bukti perangkat. Pada sesi ini ADB tidak mendeteksi perangkat: seluruh
AND-01..11 NOT RUN. iOS NOT RUN pada Windows tanpa Mac/Xcode/perangkat asli.

## Kriteria keluar

Lihat QA_GATE.md. Semua tes kritis otomatis harus PASS, tanpa bug kritis terbuka.
UAT dan perangkat nyata wajib memiliki actual result sebelum klaim FULL PASS.
