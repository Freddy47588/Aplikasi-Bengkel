# Phase 04 — Sparepart inventory ledger

Tanggal: 15 Oktober 2026, Asia/Jakarta. Repo `Freddy47588/Aplikasi-Bengkel`.
Base fork `main` pada `6d52399`, PR Phase 03 #4 sudah merged. Branch
`feat/sparepart-inventory`, worktree `D:/Portfolio-Projects/Aplikasi-Bengkel-inventory`.
**Berhenti pada Phase 04**, tanpa implementasi riwayat/invoice/pembayaran Phase 05/06.

## Pre-flight dan audit

Fetch dan fast-forward main berhasil tanpa reset/stash/force push. Checkout lama
memiliki file kosong `1.3`, `customer` dan registrant macOS lokal; dipertahankan.
Worktree fase ini dibuat dari base merged, tanpa menyalin perubahan pengguna.
Flutter tooling menyentuh generated registrants dengan normalisasi line ending;
perubahan generated tanpa diff substansi tidak masuk commit. Tidak ada AGENTS.md
berlaku. ServiceOrder typed, revision/audit, permissions users, rules default-deny,
indexes dan test actual Phase 02/03 diaudit; tidak menambahkan field inventori wajib
pada SO existing dan tidak memerlukan migrasi dokumen SO lama.

## Schema dan UX

| Path | Data / akses |
| --- | --- |
| `spareparts/{SKU}` | Admin-only master + saldo: sku, name, category, unit, supplier, buyPrice, sellPrice, minimumStock, active, stock, lowStock, stockRevision, lastMovementId, version, timestamps/actors |
| `stockMovements/{operationId}` | Admin-only immutable ledger: kind, SKU, qty, signed delta, balanceBefore/After, stockRevision, snapshot nama/satuan/harga beli/jual, actor, reason, timestamp, serviceOrderId, requestId, reversalOf |
| `serviceOrders/{so}/partUsages/{movementId}` | Immutable snapshot pemakaian/reversal: SKU, nama, satuan, qty, harga jual, actor, timestamp, referensi movement/reversal; baca sesuai ownership SO |
| `serviceOrders/{so}/partRequests/{requestId}` | Teknisi tugas sendiri membuat pending; admin approve/reject; customer tidak membaca request internal |

SKU di-trim dan uppercase, 1–40 karakter `[A-Z0-9_-]`, karakter pertama huruf/angka.
ID dokumen sama dengan SKU dan tidak dapat diubah. Create dua master SKU yang sama
berbenturan pada dokumen yang sama. Delete adalah arsip (`active=false`), tidak
menghapus master atau membebaskan SKU historis. Nama/kategori/satuan dan supplier
teks opsional dapat diedit dengan optimistic version; data yang sudah berubah
meminta reload. Semua stok/harga/minimum integer nonnegatif; qty 1–1.000.000,
stok/minimum maksimal 1.000.000.000, harga maksimal Rp1.000.000.000. Batas praktis
menjaga aritmetika integer, bukan floating-point rupiah. Master baru selalu stok 0.

Admin membuka inventori dari dashboard, mencari awalan SKU tanpa membedakan
huruf kecil/besar, filter kategori persis, active dan low-stock. `lowStock` berarti
`stock <= minimumStock`, selalu diverifikasi rules saat master/saldo berubah.
Query server, cursor 20 dokumen, sebelumnya/berikutnya, loading/empty/error/retry.
Halaman penuh dapat menawarkan satu halaman kosong berikutnya. Daftar dibaca
on demand dan tombol refresh; tidak ada listener semua stok atau agregat global.
Ledger tersedia global, per SKU, dan per SO; setiap halaman maksimal 20 dokumen.

Detail SO menyediakan pemakaian dan request. Teknisi memasukkan SKU dari label
fisik, qty dan alasan saat tugas sendiri inProgress/paused. Teknisi tidak mendapat
akses master/harga beli dan tidak menulis stok/ledger/harga jual. Admin memeriksa
permintaan dan menyetujui transaksi atau menolak dengan alasan. Request tidak
mereservasi stok. Admin juga dapat mencatat pemakaian langsung dari SO nonterminal.
Customer hanya membaca baris pemakaian/harga jual/reversal SO miliknya; harga beli
dan alasan permintaan internal tidak dibuka.

## Invariant transaksi dan rules

Satu transaksi untuk satu SKU, selalu semua reads sebelum writes:

1. Baca movement dengan operationId, master terkini, serta SO/request/original
   movement bila relevan. Jika operationId sudah ada dengan command sama, kembalikan
   hasil lama tanpa perubahan. Isi berbeda untuk ID yang sama ditolak.
2. Hitung signed delta: receipt +qty, adjustment ±qty, usage -qty, reversal
   kebalikan delta original. Tolak saldo negatif/melebihi batas. Nonreversal hanya
   pada master aktif; usage hanya pada SO nonterminal.
3. Update saldo, version +1, stockRevision +1, lastMovementId, lowStock,
   updatedAt/By; create movement immutable pada commit yang sama.
4. Untuk usage/reversal usage, create snapshot `partUsages` pada commit yang sama.
   Approval request sekaligus pending→approved dengan movementId dan keputusan.

Rules membandingkan get/getAfter master dan ledger. Update stok wajib menunjuk
movement yang belum ada, cocok SKU, revision, saldo awal/akhir, delta, actor dan
waktu server. Create movement wajib menunjuk master yang berubah dan
`lastMovementId == movementId`. Karena pointer tunggal, dua movement tidak dapat
memakai satu delta; satu movement tidak dapat mengubah dua SKU. Mengubah harga
master bersamaan dengan delta stok ditolak oleh field allowlist. Snapshot regular
harus cocok master sebelum transaksi; snapshot reversal harus cocok original.
Ledger tanpa stok, stok tanpa ledger, usage tanpa sales line, sales line tanpa
movement dan approval tanpa pemakaian ditolak. Tidak ada update/delete ledger atau
usage line. Semua writes inventori memerlukan admin aktif dengan email terverifikasi;
role users tetap operator tepercaya. Rules tidak hanya bergantung pada UI/repository.

Approval request memakai ID canonical `Q~{so}~{requestId}`, mengikat tepat satu
request pending ke satu movement. Idempotency transaksi langsung memakai ID acak
yang dibuat sekali per form. Form mengunci input setelah submit pertama dan
mempertahankan ID/command pada retry; busy guard mencegah submit/pop ganda. Timeout
setelah commit dapat diperiksa dengan retry ID yang sama tanpa decrement kedua.

Reversal **penuh, satu kali**, ID canonical `R~{originalId}`. Original tetap utuh;
tidak boleh reversal atas reversal, mengubah qty/harga/SO original, atau
menghapus movement. Reversal receipt/correction yang mengurangi saldo tetap wajib
punya stok cukup. Reversal usage membuat baris pengembalian pada SO dengan harga
snapshot original, termasuk setelah harga master berubah/part diarsipkan/SO terminal.
Tidak ada reversal otomatis saat SO dibatalkan; admin perlu audit dan reversal
eksplisit sesuai barang yang benar-benar dikembalikan.

## Keterbatasan client-only dan Spark

- Hanya Auth + Firestore. Tidak menambah dependency, Storage, Functions, upload,
  Blaze, billing upgrade, cloud seed atau layanan backend berbayar. Pengujian
  menargetkan `demo-bengkelku` lokal, bukan project produksi. Status billing project
  produksi tidak diaudit ulang; tidak ada perubahan konfigurasi billing.
- Transaction SDK memerlukan koneksi; tidak ada antrean transaksi stok offline.
  Request pending bukan reservasi; dua approval yang bersaing dapat membuat salah
  satunya gagal karena stok tidak cukup. Transaksi concurrent akan retry dengan
  saldo terbaru; rules mengunci aritmetika terhadap state commit.
- Idempotency dijamin untuk ID operasi yang sama. Dua ID berbeda adalah dua
  transaksi berbeda; client/rules tidak dapat menyimpulkan apakah dua receipt
  admin merupakan barang fisik yang sama. Admin tetap dipercaya atas kebenaran
  fisik barang, alasan, harga master dan keputusan. Rules tidak memvalidasi faktur
  supplier, kesepakatan customer, atau hitung stok fisik.
- ID form tidak dipersistenkan di perangkat setelah process-kill. Setelah hasil
  tidak pasti dan aplikasi ditutup, periksa ledger sebelum membuat form baru.
  Command lama tetap dapat diretry dengan ID yang sama melalui repository.
- Batas 1 SKU/transaksi menghindari fan-out rule lookups tidak terbatas. Tidak ada
  transaksi multi-SKU/invoice atomik, FIFO/average costing, stock reservation,
  serial/batch number, partial reversal, atau agregat total penggunaan SO.
  Baris usage dan reversal ditampilkan terpisah, bukan total dari satu halaman.
- Cursor query hemat pembacaan namun bukan snapshot lintas halaman. Refresh
  diperlukan untuk melihat perubahan admin lain; cache dan rule lookups serta
  retries tetap dapat menambah reads. Tidak mengklaim bebas biaya/kuota atau
  mengukur tagihan produksi. Tidak menghapus ledger untuk menghemat kuota.
- Rules melindungi SDK client; Admin SDK/Console bypass rules dan harus dibatasi
  pada operator tepercaya. Rules/indexes belum dideploy. Emulator tidak memaksa
  composite indexes produksi: deploy setelah review, tunggu READY dan smoke semua
  kombinasi filter/pagination. Jangan menjalankan client baru dengan rules lama.

## Pengujian

| Pemeriksaan | Hasil nyata |
| --- | --- |
| flutter pub get | PASS, dependency/lockfile unchanged |
| npm ci --no-audit --no-fund | PASS, 693 packages dari lockfile existing |
| flutter analyze | PASS, No issues found |
| flutter test | PASS, 46 tests: 38 existing + 6 inventory repository + 2 widget |
| npm run test:rules | PASS, 25 tests: 16 existing + 9 inventory rules, 0 fail |
| flutter build apk --debug | PASS, build awal 264.0s; final 38.2s |
| APK debug final | build/app/outputs/flutter-apk/app-debug.apk, 164.589.672 byte; tidak dikomit |
| git diff --check | PASS |
| Native iOS | NOT VERIFIED, Windows tanpa Mac/Xcode |
| E2E produksi / perangkat fisik | NOT RUN |

Unit tests menjalankan repository asli dengan fake Firestore: stok 5 - 2 = 3,
ledger/sales line snapshot, retry ID sama, payload berbeda pada ID sama, oversell,
master SKU duplicate/archive/stale version, reversal audit dan harga lama,
request approve/reject idempotent, bounds/low-stock dan pagination 42 master serta
25 ledger records. Fake database bukan bukti locking concurrent; bukti concurrency
berada pada rules emulator dengan transaksi SDK Firestore nyata.

Rules tests mengirim request langsung yang sengaja melanggar invariant: saldo
tanpa ledger, ledger tanpa saldo, dua ledger untuk satu delta, replay movement,
harga/actor/time palsu, qty pecahan/negatif/nol, stok minus, delta bercampur edit
harga, line snapshot hilang/palsu, approval terpisah dan unauthorized reads/writes.
Dua operasi pemakaian 4 dari stok 5 menghasilkan tepat satu pemenang dan stok 1.
Reversal receipt tanpa stok cukup ditolak; reversal usage mengembalikan qty dan
harga original, original ledger tetap ada, duplicate/reversal-of-reversal ditolak.
Harga beli tidak terbuka untuk customer/teknisi. Alasan whitespace-only ditolak,
alasan multiline diterima, dan ID regular menyisakan ruang prefix reversal.

Widget test mensimulasikan double tap sebelum frame berikutnya serta respons gagal
setelah commit pertama: retry mempertahankan ID, qty dan alasan; stok tetap 3,
bukan 1. Test lain menjalankan filter stok minimum/SKU dan form master di 320dp,
termasuk scroll dan validasi tanpa membuat master invalid. Pengujian widget SO
existing disesuaikan agar menggulir seluruh tombol dan menunggu layout sebelum
tap setelah penambahan tombol sparepart; seluruh test Phase 02/03 tetap lulus.

Review mandiri memeriksa reciprocal stock/ledger/usage/request witnesses, immutable
fields, akses harga beli, bounds, race/retry, read-before-write, query/index parity
dan rule access-call budget. Tidak ada temuan blocking yang belum terselesaikan;
review manusia dan acceptance setelah deploy tetap diperlukan.

Build masih memberi warning dependency Firebase tentang Kotlin Gradle Plugin dan
unchecked Java operations; tidak ada perubahan dependency/signing untuk menutupinya.
Pengulangan emulator sempat menemukan proses Java test fase sebelumnya tertinggal
pada port 8080. Command line/rules path diverifikasi sebelum menghentikan proses
test milik workspace ini; suite final dijalankan ulang dengan sukses. Log/cache
lokal tidak dikomit dan tidak ada test yang menulis data ke project produksi.

## File utama

- `lib/core/models/inventory.dart`, `lib/core/data/inventory_repository.dart`.
- `lib/features/inventory/presentation/inventory_screen.dart` dan
  `order_parts_screen.dart`, routing, dashboard, serta tombol sparepart pada SO.
- `firestore.rules`, `firestore.indexes.json`.
- `test/inventory_repository_test.dart`, `test/inventory_widgets_test.dart`,
  `test_rules/inventory.test.cjs`.
- README, PHASE_STATUS, ROADMAP, FIREBASE_SETUP dan laporan ini.

Native iOS **NOT VERIFIED**: host Windows tanpa Mac/Xcode, konfigurasi Firebase
iOS asli belum ditambahkan. E2E produksi/perangkat fisik belum dijalankan. Tidak
ada auto-merge/force push; PR fork main membutuhkan review manusia.
