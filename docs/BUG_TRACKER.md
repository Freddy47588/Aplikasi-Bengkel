# Bug dan gap Phase 07

Pembaruan 13 November 2026, audit dimulai 12 November pada base `828fc59`.
Tiga bug runtime baru direproduksi dan diperbaiki; detail serta hasil perintah
pada [audit penuh](FULL_APP_AUDIT_REPORT.md) dan [regresi](REGRESSION_RESULTS.md).
QA-13 tetap OPEN: race katalog berikut tidak membuktikan penyebab laporan
dropdown native yang lama. ADB sesi ini kosong; UAT tetap NOT RUN.

| ID | Severity | Temuan / reproduksi | Status | Perbaikan / bukti |
| --- | --- | --- | --- | --- |
| QA-14 | P1 High | Hapus layanan setelah validasi sebelum frame submit; `firstWhere` melempar StateError | FIXED | Snapshot nullable dan guard readiness; tes gagal sebelum fix, lulus sesudah; tidak ada write |
| QA-15 | P2 Medium | Dua konfirmasi sebelum rebuild membuka dua dialog | FIXED | Lock sejak review, cancel membuka form lagi; satu dialog dan nol write pada cancel |
| QA-16 | P2 Medium | Laporan menerima 31 hari + 1 detik | FIXED | Durasi utuh dibandingkan 31 hari; tes batas positif/negatif |
| QA-17 | P3 Low, tooling | Dua tap test berada di luar viewport dan dua lint lokal | FIXED pada working tree | Reveal sebelum tap tanpa menghapus assertion; dua lint dibersihkan. Perubahan pada file yang sudah dirty tidak masuk commit audit |

Gap F-02: admin belum memiliki CRUD kendaraan pelanggan, hanya snapshot pada
booking/SO. Perlu keputusan scope/otorisasi terpisah, bukan pelonggaran rules.
Notifikasi belum diimplementasikan, bukan bug runtime. QA-01 tetap ACCEPTED
LIMITATION. Tidak ada verifikasi/deploy production baru; catatan berikut
dipertahankan sebagai riwayat tanggal masing-masing.

Pembaruan 6 November 2026. QA-11 FIXED, pemetaan loopback otomatis SDK
menghalangi adb reverse pada Infinix; commit 9ffb1ec dan test routing red/green.
QA-12 FIXED, Android menolak HTTP emulator; commit 316b6ab dan dua test jaringan
red/green. Login tiga role di HP PASS setelah kedua perbaikan.
QA-13 OPEN untuk triase, laporan tap Jenis layanan tanpa daftar belum
tereproduksi pada build emulator 316b6ab. Lima layanan terbuka, pilihan Ganti Oli
dan kirim booking berhasil. Perlu cocokkan build/katalog pada laporan awal.
QA-02 tetap OPEN untuk sisa AND/black-box dan UAT, meskipun perangkat sudah tersedia.
QA-03 kini menyisakan indexes/READY dan smoke production. Rules sudah dirilis
pada sesi terpisah sebelumnya dengan persetujuan pengguna. Bukti pada
[hasil perangkat](PHASE_07_DEVICE_RESULTS.md).

Tanggal 5 November 2026 WIB. Severity: critical = akses tidak sah/kehilangan data;
high = transaksi utama salah; medium = kebutuhan fitur/acceptance belum terpenuhi;
low = dokumentasi/tooling. Bukti source dipisahkan dari hasil runtime.

| ID | Severity | Temuan | Bukti/reproduksi | Status | Tindakan / uji ulang |
| --- | --- | --- | --- | --- | --- |
| QA-01 | Medium | Admin tidak memiliki UI CRUD katalog layanan | README menyatakan operator Console; tidak ada screen CRUD services | ACCEPTED LIMITATION (Phase 07) | 6 Nov: pengguna mendelegasikan keputusan; Console diterima sebagai batas scope Phase 07. Tidak mengklaim full CRUD mobile. UI katalog untuk TA memerlukan instruksi terpisah; BB-A16 tetap BLOCKED, bukan PASS |
| QA-02 | Medium | UAT pengguna nyata dan smoke Infinix belum dilakukan | ADB tidak mendeteksi perangkat; tidak ada form responden terisi | OPEN | Jalankan TEST_PLAN AND-01..11 dan UAT; lampirkan bukti asli |
| QA-03 | Medium | Index READY dan Rules production belum diverifikasi/deploy | Scope sesi tidak mengizinkan deploy otomatis | OPEN | Operator review, persetujuan terpisah, READY dan smoke queries |
| QA-04 | Medium | Snapshot part invoice saat issue mempercayai admin | PAYMENT_SCHEMA.md; rules issued tidak fold ledger part dinamis | ACCEPTED LIMITATION | Rekonsiliasi ledger oleh operator; bukan klaim pencegahan fraud admin |
| QA-05 | Low | Native iOS belum diuji | Windows tanpa Mac/Xcode/Firebase iOS nyata | OPEN | Build dan acceptance pada Mac/iPhone/iPad |
| QA-06 | Medium | Belum ada mode Flutter terisolasi untuk login fixture | main awal selalu DefaultFirebaseOptions production | FIXED | API demoProjectId pada app bernama, provider scoped, guard PASS, 102 tes Flutter/analyze/APK PASS; acceptance native tetap NOT RUN |
| QA-07 | Medium | Belum ada seed/reset lintas modul dengan real Auth | Audit tools dan test existing sebelum perubahan | FIXED | Seed rules-enforced, manifest, relasi dan reset; integrasi final + 8 CLI cycle PASS |
| QA-08 | Medium | Preflight integrasi timeout saat memakai laporan ruleCoverage setelah suite negatif | Run emulator pertama: 37 PASS, integrasi gagal sebelum seed (10 detik) | FIXED | Probe bounded + token owner emulator-only, timeout 30 detik dan pesan berlokasi; guard tetap aktif; final 38/38 PASS |
| QA-09 | Medium | Helper trusted tidak mengembalikan nilai callback SDK | Retest: preflight lolos, reset gagal membaca manifest undefined | FIXED | Capture hasil callback Promise<void>; integrasi targeted dan final 38/38 PASS |
| QA-10 | Low | Test splash gagal pada Linux karena nama file font SDK case-sensitive | CI awal 42022724423: PathNotFoundException untuk roboto-regular/medium/bold.ttf; Windows sebelumnya PASS | FIXED | Gunakan Roboto-Regular/Medium/Bold/Black.ttf dan MaterialIcons-Regular.otf sesuai arsip resmi SDK pada dua test; retest lokal 34/34 PASS; hasil CI ulang dicatat pada PHASE_07_REPORT |

Tidak ada bug kritis baru yang dinyatakan tertutup tanpa reproduksi dan uji
ulang. ACCEPTED LIMITATION adalah batas desain existing, bukan hasil pengujian
PASS. Temuan baru dari perangkat/UAT harus menambahkan langkah, expected,
actual, build, role, severity, bukti, pemilik, dan hasil retest.
