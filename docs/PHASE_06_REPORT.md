# Phase 06 - pembayaran manual, invoice PDF dan laporan

Tanggal: 15 Oktober 2026, Asia/Jakarta. Branch `feat/payments-invoices-reports`,
base `44f7cce` (PR #6 Phase 05 merged). Target PR hanya `Freddy47588:main`.

## Pre-flight dan hasil

Fetch origin berhasil. Checkout utama dirty: perubahan registrant macOS dan file
untracked dipertahankan. Main tidak dipull/switch paksa. Worktree terpisah
`D:/Portfolio-Projects/Aplikasi-Bengkel-payments` dibuat dari origin/main terbaru.
Tidak ada auto-merge, force push, atau perubahan pada checkout fase lain.

Audit menemukan laborPrice SO disahkan sebelum completed, partUsages menyimpan
snapshot sellPrice, reversal memakai harga original, dan ledger terkunci setelah
SO terminal. Invoice memakai sumber immutable ini, tidak membaca harga master.
Admin/kasir mencatat tunai atau transfer yang diperiksa manusia. Tidak ada
integrasi bank. Kasir memakai role admin existing, bukan role baru.

Invoice deterministik per SO, harga integer, diskon/biaya beralasan, pembayaran
bertahap, kembalian tunai dan transisi unpaid/partial/paid/void/refunded. Transaksi
mewajibkan event audit immutable. Double submit memakai key + revisi; replay
memeriksa payload dan actor. Error race rules direkonsiliasi dengan event server
identik, bukan write ulang. Void/refund manual penuh dikonfirmasi eksplisit.

Dashboard/SO menyediakan akses transaksi, filter WIB, detail invoice, audit,
cetak/share lokal. Pelanggan hanya dapat membaca invoice sendiri. Laporan
berasal dari booking, SO, invoice lunas, movement dan stok nyata; partial/unpaid
tidak masuk omzet. Omzet tidak diklaim sebagai laba. Pagination 20 dokumen dan
laporan on-demand maksimal 31 hari, tanpa listener seluruh koleksi.

PDF dibuat dengan `pdf` 3.13.1 dan `printing` 5.15.1; Noto Sans OFL dibundel agar
tidak mengambil font jaringan. Tidak memakai Storage, Functions, gateway, Blaze,
atau upload PDF ke backend. Font dan license ada di assets/fonts.
Lihat [schema lengkap](PAYMENT_SCHEMA.md) untuk invariant, index dan biaya reads.

## Validasi

| Pemeriksaan | Hasil nyata |
| --- | --- |
| flutter pub add pdf printing | PASS, pubspec/lockfile diperbarui |
| npm ci | PASS, 693 packages; tooling existing mengeluarkan peringatan deprecated |
| flutter analyze --no-pub final | PASS, No issues found (56,7 detik) |
| flutter test --no-pub | PASS, 62 tests (52 regresi + 10 baru) |
| Targeted repository setelah penyesuaian order query index | PASS, 8 tests |
| Rules Firestore + Auth emulator | PASS, 35 tests, 0 gagal (28 regresi + 7 baru) |
| flutter build apk --debug --no-pub awal | PASS, 608,5 detik |
| APK final | PASS, rebuild 46,7 detik; 170.895.648 byte |
| Android install/startup | PASS install --no-streaming dan cold start 5,6 detik dengan software-rendering/Impeller-off workaround emulator |
| PDF generator lokal | PASS, bytes %PDF-, snapshot dan WIB; file dibuka di viewer Android |
| Native print/share dari aplikasi | Belum diverifikasi end-to-end dengan akun Firebase |
| Native iOS / PDF iOS di Mac | NOT VERIFIED: host Windows, tanpa Mac/Xcode dan konfigurasi Firebase iOS asli |
| git diff --check | PASS |

APK lokal: `build/app/outputs/flutter-apk/app-debug.apk`, SHA256
`7482A9624FF34CC55CCA4BFD2BB8E0AB11B1503B5BE2C8B6DD43D2D83A35019B`.
APK/log tidak dikomit. Warning KGP Firebase dan unchecked Java existing tidak
menggagalkan build. Cold start memakai workaround grafis emulator historis;
stabilitas rendering default/perangkat fisik belum diverifikasi pada fase ini.

Repository tests menguji subtotal jasa/part/reversal/diskon/biaya dengan integer,
snapshot lama setelah master diubah, key replay/mismatch, revisi stale,
partial/pelunasan/kembalian, transfer overpay, void/refund terminal, pembatasan
customer, unpaid/partial/refund dikeluarkan dari omzet, seluruh halaman report,
active lowStock, format rupiah dan WIB serta bytes PDF lokal. Widget tests
memverifikasi detail admin/customer pada 320dp skala 1,3, visibility aksi dan
cancel konfirmasi tidak menulis payment.

Rules tests memakai SDK Firestore sesungguhnya: issue canonical + audit atomik,
customer isolation, query report admin, bounded pagination, double submit
serentak dengan satu event, saldo/kembalian benar, float/tampering ditolak,
snapshot/event immutable, transfer overpay ditolak, void/refund terminal.
Percobaan awal menemukan dropdown overflow (diperbaiki) dan race rules menolak
loser transaksi sebelum retry SDK (ditangani dengan replay event server identik).

Port 8080 emulator existing sedang terpakai. Suite final memakai konfigurasi
lokal ignored dengan Firestore 8180, Auth 9199, hub 4500, logging 4600. Tidak
menghentikan emulator proyek lain. JVM awal salah menunjuk folder JBR lama;
pengujian final memakai Java 22 yang tersedia. Log lokal diabaikan Git.

Android emulator Pixel_6 API 37 sempat System UI ANR saat boot. Sesudah menutup
dialog, PDF lokal fixture dibuka melalui content URI provider Android (bukan
file URI yang dibatasi scoped storage). Viewer menampilkan judul, snapshot
jasa/part, total Rp185.000, status unpaid, sisa dan WIB dengan benar; screenshot
ditinjau. Ini membuktikan PDF dapat dirender Android, bukan alur print/share
aplikasi dengan data production. Bukti lokal di build/phase06-pdf.png dan PDF
fixture build/phase06-invoice.pdf; tidak diunggah atau dikomit.

## Biaya, deploy dan known risks

- Tetap Spark; tidak ada provisioning layanan berbayar, deploy production atau
  perubahan billing. Kuota aktual console tidak diperiksa. Report reads bertambah
  menurut jumlah dokumen hasil query; batas 31 hari bukan batas jumlah reads.
- Rules memvalidasi otorisasi, identitas SO, jasa, aritmetika invoice dan setiap
  perubahan saldo + audit. Snapshot part/subtotal awal disahkan admin tepercaya;
  rules tidak melakukan fold semua baris part dinamis. Admin dengan client
  modifikasi dapat menyimpang saat issue. Rekonsiliasi ledger operator diperlukan.
- Refund hanya penuh dan final. Omzet paid merupakan laporan status invoice
  menurut paidAt, bukan laporan laba/arus kas; refund mengubah omzet historis
  periode pelunasan. Laporan beberapa query tidak atomik lintas koleksi.
- Nomor invoice unik berbasis SO ID, bukan penomoran faktur pajak berurutan.
  Invoice total nol ditolak; maksimal 100 baris part. Tidak ada approval dua petugas.
- Key UI bertahan selama layar/proses untuk retry, bukan antrean offline persisten.
  Transaksi memerlukan jaringan. Setelah restart, periksa audit sebelum mencatat
  pembayaran baru jika hasil operasi sebelumnya tidak diketahui.
- Review dan deploy rules/indexes bersamaan, tunggu READY sebelum acceptance
  production. Konfigurasi Firebase iOS dan native print/share perlu diuji di Mac.

**STOP PHASE 06.** Phase 07/08 tidak dikerjakan; PR perlu review sebelum merge.
