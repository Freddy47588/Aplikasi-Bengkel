# Audit aplikasi BengkelKu, 12-13 November 2026

Audit Phase 07 pada `main`, base `828fc59b656f43d93ddbc07901f27b57172dd011`.
Tanggal menggunakan Asia/Jakarta. Audit dilakukan pada Windows dengan Flutter
3.44.2/Dart 3.12.2, Firebase Auth/Firestore Emulator `demo-bengkelku`.
Hasil final per perintah, CI dan identitas source ada di
[REGRESSION_RESULTS.md](REGRESSION_RESULTS.md). Ini bukan pernyataan bebas bug.
Source perbaikan akhir `728deb4f04b49f1911e76202bdff76de78d740cf` telah dipush
normal ke origin/main dan CI PASS (140 Flutter/39 Firebase). Working tree lokal
PASS 142 Flutter/40 Firebase, analyze/format dan APK; selisih dijelaskan di bawah.

## Cakupan dan perlindungan pekerjaan lokal

Preflight: fetch berhasil, HEAD dan origin/main sama, branch main. Tidak membuat
branch/PR, reset atau force push. Identitas Git Freddy47588 sesuai konfigurasi.
Ada 20 path tracked yang dirty serta tiga file untracked sebelum audit,
termasuk perubahan kendaraan/model/rules, dashboard, test dan dokumen UAT.
Patch binary dan salinan file awal disimpan di luar repo pada
`D:/Portfolio-Projects/.bengkelku-tools/audit-20261112/preexisting/`.

Perubahan tersebut dipertahankan dan tidak dimasukkan ke commit audit.
Pembersihan dua lint pada dashboard/kendaraan serta perbaikan langkah tap pada
`test/customer_mockup_test.dart` hanya melengkapi working tree lokal dan tetap
tidak dipublikasikan. Tidak mengklaim schema kendaraan lokal sebagai perubahan
schema yang dikirim sesi ini. Hasil working tree dan CI harus dibaca terpisah.

Inventaris seluruh 66 file Dart aplikasi mencakup app/router/theme, core
data/models/widgets dan seluruh feature. Pemeriksaan source lebih dalam
difokuskan pada Auth/session, form booking/katalog, repository transaksi,
provider ownership, navigasi, pagination, history dan payment/report.
Seluruh test Flutter serta tujuh suite Firebase dijalankan. Konfigurasi Android,
iOS, assets, pubspec, tools/seed, test_data, workflow, rules dan 35 indeks ditinjau.
Inventaris berisi 224 path, termasuk 66 Dart aplikasi dan 31 Dart test/helper.
Daftar path dan hash source yang diuji disimpan dalam manifest evidence.
Inventaris file bukan bukti setiap jalur runtime telah dieksekusi.

Dokumen historis README, PHASE_STATUS, PHASE_07_REPORT, PHASE_07_DEVICE_RESULTS,
QA_GATE, BUG_TRACKER, BLACK_BOX_RESULTS, SECURITY_AUDIT, UI_UX_AUDIT,
UI_VISUAL_FIDELITY_REPORT, TEST_DATA_GUIDE dan UAT_TEST_PLAN ditinjau. Status
historis tidak diwariskan sebagai hasil run baru.

## Temuan dan perbaikan

| ID | Prioritas | Sebelum | Akar masalah / perubahan | Setelah |
| --- | --- | --- | --- | --- |
| QA-14 | P1 | Katalog menghilang setelah form tervalidasi tetapi sebelum frame berikut: submit melempar `Bad state: No element` | `submit()` membaca `requireValue.firstWhere` di luar try. Pilihan dicari secara nullable dari snapshot provider yang siap; beri feedback jika berubah, pertahankan input | PASS tes red/green |
| QA-15 | P2 | Dua panggilan konfirmasi sebelum rebuild membuka dua dialog | Flag busy baru diset sesudah dialog. Guard sinkron dan flag reviewing sekarang melindungi fase review; cancel membuka form kembali | PASS, satu dialog, cancel tidak menulis booking |
| QA-16 | P2 | Periode 31 hari + 1 detik diterima laporan | `Duration.inDays` membulatkan ke bawah. Bandingkan durasi utuh dengan 31 hari | PASS, batas 31 hari diterima, lebih ditolak |
| QA-17 | P3, tooling | Dua tes lama salah tap di luar viewport; dua lint pada perubahan lokal awal | Scroll/reveal sebelum tap, hapus import tidak terpakai, gunakan null-aware set. Assertion dan fitur tetap ada | PASS analyze, format dan 142 tes working tree |

Total bug runtime baru terverifikasi: P0 0, P1 1, P2 2, P3 0. QA-17 adalah satu
kelompok empat masalah validasi, bukan empat kegagalan aplikasi. Tidak ada
kebocoran atau transaksi ganda yang ditemukan dalam cakupan suite; ini tidak
menjamin semua skenario aman tanpa pengujian tambahan.

QA-13 (tap dropdown tanpa daftar pada perangkat laporan awal) tetap OPEN untuk
reproduksi native/build/katalog yang sama. Pengujian otomatis membuktikan opsi
tersedia dapat dipilih, layanan dihapus tidak menyisakan pilihan valid, katalog
kembali dapat dibuka, error punya retry, dan race QA-14 sudah diperbaiki.
Temuan ini tidak cukup untuk menyatakan penyebab laporan native QA-13 identik.

## Alur dan batas sistem

Pelanggan: register/login/reset/verifikasi/profil, kendaraan milik sendiri,
booking/review/cancel, tracking, riwayat dan invoice dipetakan ke route/provider
dan test pada [matriks fitur](FUNCTIONAL_BUG_MATRIX.md).
Admin: dashboard/booking, direktori teknisi, SO/assignment/review, master/ledger/
request/reversal, invoice/partial/paid/void/refund/PDF dan laporan.
Teknisi: dashboard/tugas sendiri, start/pause/resume/checklist/diagnosis/tindakan,
request sparepart dan pengajuan penyelesaian. Completion tetap melalui admin.

Transaksi slot booking, revisi SO, lock teknisi, ledger stok, snapshot harga,
idempotency pembayaran dan audit immutable tidak diubah. Suite emulator
menguji kasus negatif, race dan efek akhir data. Tidak ada perubahan Rules,
indeks, billing, production, migrasi, Google Sign-In atau Cloud Functions oleh
audit ini. Rules lokal awal ikut diuji, namun tidak ikut commit audit.

Tidak ada implementasi notifikasi pada source yang diperiksa: tidak ada
provider/koleksi/inbox/unread/mark-read atau FCM. Ini fitur belum tersedia,
bukan bug runtime. Tidak dibuat lonceng dummy atau infrastruktur push baru.

Batas existing dipertahankan: kendaraan/katalog 50, booking 100; SO/teknisi,
history/ledger/invoice berhalaman 20. Pencarian tertentu hanya halaman yang
dimuat; UI menyebut batasnya. Laporan melakukan query server berdasarkan
periode. Riwayat immutable memakai snapshot, bukan harga master terbaru.
Dokumen malformed bisa menghasilkan error provider; recovery setiap bentuk
data rusak belum diuji secara exhaustif. Native offline/reconnect dan biaya
baca production belum diukur. Tidak melakukan optimasi spekulatif.

## Kesesuaian TA dan acceptance

Pemetaan F-01..F-09 memakai tabel kebutuhan pada lampiran prompt terdahulu
`f88be824-21a0-452a-a1b2-9edfb6ec0615/Pasted text.txt`, baris 96-105, dan dokumen
repo. Dokumen TA asli DOCX/PDF tidak tersedia pada lampiran sesi ini, sehingga
kutipan asli serta acceptance dosen/pemilik masih perlu verifikasi.

F-02 mencantumkan kewenangan admin: aplikasi saat ini memberi admin snapshot
kendaraan pada booking/SO, bukan CRUD kendaraan semua pelanggan. Ini gap
kebutuhan/otorisasi, bukan kegagalan runtime. Perlu keputusan scope terpisah;
jangan membuka rules ownership demi memenuhi istilah CRUD. UI CRUD katalog
admin tetap QA-01, ACCEPTED LIMITATION Phase 07. Peran users hanya operator
tepercaya, archive tidak sama dengan hard delete, dan ledger tidak boleh dihapus.

ADB tidak mendeteksi perangkat pada sesi 12-13 November. AND-01..AND-11 sesi ini
NOT RUN; bukti Infinix 6 November tetap arsip historis. iOS NOT RUN pada host
Windows. UAT pengguna nyata NOT RUN. Native print/share, font sistem terbesar,
rotasi, process kill, putus jaringan saat transaksi dan smoke production tetap
perlu bukti perangkat. QA acceptance tetap BLOCKED; Phase 08 tidak dimulai.

Prioritas selanjutnya: (1) Infinix emulator-isolated AND-03..07/09/10 dan QA-13;
(2) UAT tiga role dengan actual result; (3) sepakati gap admin kendaraan/katalog,
kemudian acceptance iOS serta smoke production yang diotorisasi terpisah.
