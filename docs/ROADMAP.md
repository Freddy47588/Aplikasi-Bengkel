# Roadmap BengkelKu (fork)

Pembaruan penutupan Phase 07, 6 November 2026 WIB. Platform Android dan iOS memakai satu codebase Flutter;
web, Windows, Linux, dan macOS tetap dipertahankan. Dokumen ini adalah rencana,
bukan klaim implementasi atau izin memulai fase selanjutnya.

| Fase | Branch | Cakupan | Status |
| --- | --- | --- | --- |
| 01 | `fix/mobile-foundation` (existing) | Demo tiga role, guard lokal, booking in-memory, navigasi, branding, Android debug | Audit final; lihat PHASE_STATUS.md |
| 02 | `feat/firebase-auth-booking` | Identitas produksi, RBAC backend, kendaraan, persistensi dan kapasitas booking | Merged PR #3; lihat PHASE_02_REPORT.md |
| 03 | `feat/technician-service-orders` | Teknisi, assignment, checklist, diagnosis dan progres teks | Merged PR #4; lihat PHASE_03_REPORT.md |
| 04 | `feat/sparepart-inventory` | Master sparepart, ledger, permintaan, pemakaian SO, reversal dan stok minimum | Merged PR #5; lihat PHASE_04_REPORT.md |
| 05 | `feat/service-history-tracking` | Riwayat dari servis selesai, pelacakan pelanggan | Implementasi untuk review PR; lihat PHASE_05_REPORT.md |
| 06 | Riwayat implementasi; lihat laporan | Pembayaran manual, invoice lokal, laporan | Source dan test existing tersedia; lihat PHASE_06_REPORT.md |
| 07 | `main` saja | Integrasi, keamanan backend, black-box, UAT faktual, CI | Otomatis PASS pada run terdokumentasi; acceptance BLOCKED, lihat QA_GATE.md |
| 08 | Belum dimulai | Signing asli, build native iOS, kesiapan distribusi | NOT RUN; tidak dimulai otomatis |

Nama branch fase lama di atas adalah riwayat, bukan instruksi membuat branch.
Penutupan Phase 07 hanya memakai main, tanpa branch/PR baru, deploy atau force push.
Phase 01 adalah riwayat demo in-memory; source fase berikutnya memakai Auth/Firestore.

Urutan penutupan: verifikasi emulator/seed/reverse dan build debug pada Infinix;
AND-01..11 serta black-box tiga role dengan bukti asli; UAT oleh pengguna nyata;
retest bug yang terbukti dengan regression test; evaluasi gate kembali.
QA-01: pengelolaan katalog melalui Console diterima sebagai batas scope Phase 07
berdasarkan keputusan yang didelegasikan pengguna pada 6 November. UI CRUD katalog
tetap tidak tersedia dan tidak diklaim full CRUD mobile. Jika dibutuhkan oleh TA,
implementasinya memerlukan instruksi terpisah; tidak ditambahkan pada penutupan ini.

Batas sebelum produksi: identitas dan otorisasi backend, persistensi lintas perangkat,
kapasitas slot transaksional, signing asli, serta pengujian Mac/Xcode dan perangkat.
