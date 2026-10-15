# Roadmap BengkelKu (fork)

Status per 15 Oktober 2026. Platform Android dan iOS memakai satu codebase Flutter;
web, Windows, Linux, dan macOS tetap dipertahankan. Dokumen ini adalah rencana,
bukan klaim implementasi atau izin memulai fase selanjutnya.

| Fase | Branch | Cakupan | Status |
| --- | --- | --- | --- |
| 01 | `fix/mobile-foundation` (existing) | Demo tiga role, guard lokal, booking in-memory, navigasi, branding, Android debug | Audit final; lihat PHASE_STATUS.md |
| 02 | `feat/firebase-auth-booking` | Identitas produksi, RBAC backend, kendaraan, persistensi dan kapasitas booking | Merged PR #3; lihat PHASE_02_REPORT.md |
| 03 | `feat/technician-service-orders` | Teknisi, assignment, checklist, diagnosis dan progres teks | Implementasi; lihat PHASE_03_REPORT.md. Menunggu review PR |
| 04 | `feat/sparepart-inventory` | Master sparepart, ledger, stok minimum | Rencana |
| 05 | `feat/service-history-tracking` | Riwayat dari servis selesai, pelacakan pelanggan | Rencana |
| 06 | `feat/payments-invoices-reports` | Pembayaran manual, invoice lokal, laporan | Rencana |
| 07 | `test/uat-security-ci` | Integrasi, keamanan backend, black-box, UAT faktual, CI | Rencana |
| 08 | `chore/android-ios-release` | Signing asli, build native iOS, kesiapan distribusi | Rencana |

Setiap PR menargetkan `Freddy47588/Aplikasi-Bengkel:main`, tanpa auto-merge atau
force push. PR ke upstream merupakan jalur terpisah. Phase 01 berhenti pada demo
in-memory; Firebase, inventori, dan pembayaran produksi tidak ditambahkan.

Batas sebelum produksi: identitas dan otorisasi backend, persistensi lintas perangkat,
kapasitas slot transaksional, signing asli, serta pengujian Mac/Xcode dan perangkat.
