# Bug dan gap Phase 07

Tanggal 5 November 2026 WIB. Severity: critical = akses tidak sah/kehilangan data;
high = transaksi utama salah; medium = kebutuhan fitur/acceptance belum terpenuhi;
low = dokumentasi/tooling. Bukti source dipisahkan dari hasil runtime.

| ID | Severity | Temuan | Bukti/reproduksi | Status | Tindakan / uji ulang |
| --- | --- | --- | --- | --- | --- |
| QA-01 | Medium | Admin tidak memiliki UI CRUD katalog layanan | README menyatakan operator Console; tidak ada screen CRUD services | OPEN | Gap kebutuhan TA; sepakati cakupan implementasi sebelum klaim full CRUD. Rules positif/negatif katalog tetap diuji. Tidak menambah UI pada fase QA |
| QA-02 | Medium | UAT pengguna nyata dan smoke Infinix belum dilakukan | ADB tidak mendeteksi perangkat; tidak ada form responden terisi | OPEN | Jalankan TEST_PLAN AND-01..11 dan UAT; lampirkan bukti asli |
| QA-03 | Medium | Index READY dan Rules production belum diverifikasi/deploy | Scope sesi tidak mengizinkan deploy otomatis | OPEN | Operator review, persetujuan terpisah, READY dan smoke queries |
| QA-04 | Medium | Snapshot part invoice saat issue mempercayai admin | PAYMENT_SCHEMA.md; rules issued tidak fold ledger part dinamis | ACCEPTED LIMITATION | Rekonsiliasi ledger oleh operator; bukan klaim pencegahan fraud admin |
| QA-05 | Low | Native iOS belum diuji | Windows tanpa Mac/Xcode/Firebase iOS nyata | OPEN | Build dan acceptance pada Mac/iPhone/iPad |
| QA-06 | Medium | Belum ada mode Flutter terisolasi untuk login fixture | main awal selalu DefaultFirebaseOptions production | FIXED | API demoProjectId pada app bernama, provider scoped, guard PASS, 102 tes Flutter/analyze/APK PASS; acceptance native tetap NOT RUN |
| QA-07 | Medium | Belum ada seed/reset lintas modul dengan real Auth | Audit tools dan test existing sebelum perubahan | FIXED | Seed rules-enforced, manifest, relasi dan reset; integrasi final + 8 CLI cycle PASS |
| QA-08 | Medium | Preflight integrasi timeout saat memakai laporan ruleCoverage setelah suite negatif | Run emulator pertama: 37 PASS, integrasi gagal sebelum seed (10 detik) | FIXED | Probe bounded + token owner emulator-only, timeout 30 detik dan pesan berlokasi; guard tetap aktif; final 38/38 PASS |
| QA-09 | Medium | Helper trusted tidak mengembalikan nilai callback SDK | Retest: preflight lolos, reset gagal membaca manifest undefined | FIXED | Capture hasil callback Promise<void>; integrasi targeted dan final 38/38 PASS |

Tidak ada bug kritis baru yang dinyatakan tertutup tanpa reproduksi dan uji
ulang. ACCEPTED LIMITATION adalah batas desain existing, bukan hasil pengujian
PASS. Temuan baru dari perangkat/UAT harus menambahkan langkah, expected,
actual, build, role, severity, bukti, pemilik, dan hasil retest.
