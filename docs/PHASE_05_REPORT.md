# Phase 05 — Service history and live tracking

Tanggal: 15 Oktober 2026, Asia/Jakarta. Repo `Freddy47588/Aplikasi-Bengkel`.
Base `main` `2f82b76`, merge PR #5 (Phase 04). Branch
`feat/service-history-tracking`, worktree `D:/Portfolio-Projects/Aplikasi-Bengkel-history`.
**STOP PHASE 05**, tanpa implementasi pembayaran, invoice, laporan atau release.

## Pre-flight dan keputusan sumber data

Fetch origin dan sinkronisasi main fast-forward: sudah up to date. Perubahan
lokal pengguna di checkout utama (registrant macOS, file kosong `1.3`, `customer`)
dipertahankan; pekerjaan fase ini memakai worktree bersih dari base merged.
Tidak ada AGENTS.md yang berlaku. Tidak ada reset, stash atau force push.

Audit menemukan SO terminal sudah immutable, snapshot booking disalin saat
create, partUsages memakai harga jual saat movement, dan reversal memakai harga
original. Celah yang ditutup: reversal usage sebelumnya masih boleh ditambahkan
sesudah SO terminal. Sekarang usage **dan reversal usage** memerlukan SO
nonterminal di repository dan rules `getAfter`, sehingga baris riwayat beku
ketika SO diselesaikan. Reversal stok penerimaan/koreksi tetap tersedia.

Tidak membuat `serviceHistories`: sumber tunggal adalah `serviceOrders` completed
dan immutable `partUsages` miliknya. Tidak ada formulir input riwayat kedua atau
proses sinkronisasi yang dapat terlewat. Completion SO, timestamp server, event
audit dan pelepasan lock teknisi tetap satu transaksi.

## Implementasi

- Route riwayat/detail untuk customer, admin dan teknisi. Customer query selalu
  customerId sesi; teknisi hanya technicianId sesi, mengikuti assignment terakhir.
  Teknisi yang sudah dialihkan tidak mendapat akses riwayat tugas tersebut.
- Admin aktif berwenang atas bengkel tunggal dalam Firebase project ini; tidak ada
  dukungan multi-tenant. Role/provisioning tetap hanya operator tepercaya.
- Detail: booking ID, SO ID, kendaraan/plat snapshot, keluhan, diagnosis, tindakan,
  nama/ID teknisi, jenis jasa, snapshot biaya jasa, semua sparepart/reversal dengan
  qty/satuan/harga jual, subtotal, total dan tanggal selesai WIB.
- `laborPrice`: integer rupiah 0–1.000.000.000; admin mencatat sebelum completion
  (0 harus eksplisit), revision + event pricingUpdated atomik, menolak stale write.
  Tidak ada harga master jasa pada schema lama, sehingga biaya jasa dicatat per SO.
- `technicianName`: snapshot nama direktori pada assignment. Rename master teknisi
  kemudian tidak mengubah riwayat. SO legacy tanpa nama mendapat snapshot nama
  saat completion; riwayat completed lama tetap boleh hanya menampilkan ID.
- Semua field SO terminal dan baris usage/reversal immutable; tidak ada join ke
  harga master ketika menghitung riwayat. Reversal mengurangi qty × harga original.
- Total baru tampil setelah seluruh halaman sparepart berhasil dimuat (20 per
  request). Error tidak menghasilkan total parsial; cache diberi peringatan dan
  tidak dipresentasikan sebagai total lengkap.
- SO completed lama tanpa snapshot jasa menampilkan “tidak tercatat”; tidak
  mengarang harga nol atau memakai harga master terbaru untuk data lama.
- Status pembayaran “Belum dicatat”. Belum ada sumber pembayaran sebelum Phase 06,
  sehingga tidak mengklaim unpaid/paid berdasarkan asumsi.
- Filter kendaraan, jenis servis (ID stabil), periode tanggal WIB, reset filter
  mereset cursor. Pintasan kendaraan milik customer termasuk arsip (maks. 50),
  pintasan jenis servis aktif; input ID mendukung data historis di luar pintasan.
- Query completedAt descending + ID ascending, startAfterDocument, 20 per halaman.
  12 composite indexes: tiga scope role × empat kombinasi vehicle/service filter.
  Rentang `[awal tanggal WIB, hari setelah akhir WIB)` inklusif untuk pilihan hari.
- Loading, empty, error/retry dan metadata cache. Listener memperbarui daftar saat
  tersambung kembali. Pagination maju ditahan untuk hasil cache yang mungkin parsial.
- Detail menolak SO belum selesai dan memeriksa ownership sesi lagi, termasuk
  untuk snapshot cache saat akun berganti. Firestore rules tetap otoritas backend.

Pemetaan timeline eksplisit:

| Sumber | Tahap |
| --- | --- |
| booking pending | pending |
| booking confirmed tanpa SO, SO queued | confirmed |
| SO assigned | assigned |
| SO inProgress, paused, awaitingApproval | inProgress, dengan label keadaan aktual |
| SO completed | completed |
| booking rejected/cancelled, SO cancelled | Berhenti, tidak ditampilkan sebagai completed |

Booking tetap confirmed selama servis; UI mengambil progres dari SO setelah
dibuat. Timeline adalah keadaan saat ini, bukan tanggal/log seluruh pause/resume
atau rework. Event revisi tetap immutable. Tidak ada Storage, Functions, upgrade
Blaze, export dokumen, upload file atau payment gateway.

## Validasi

| Pemeriksaan | Hasil nyata |
| --- | --- |
| flutter pub get | PASS; dependency/lockfile tidak berubah |
| npm ci --no-audit --no-fund | PASS; 693 packages dari lockfile existing |
| flutter analyze; pengulangan final --no-pub | PASS; No issues found, final 70,8 detik |
| flutter test; pengulangan final --no-pub | PASS; 52 tests (46 regresi + 6 baru), 0 gagal |
| npm run test:rules | PASS; 28 tests (25 regresi + 3 baru), 0 gagal |
| flutter build apk --debug | PASS; build awal 452,3 detik |
| Build ulang final --no-pub | PASS; final 27,8 detik |
| git diff --check | PASS |
| Native iOS | NOT VERIFIED; Windows tanpa Mac/Xcode |

Log lokal diabaikan Git: `phase05-analyze.log`, `phase05-analyze-final.log`,
`phase05-tests-final.log`, `phase05-rules.log`, `phase05-build-final.log`.
Tidak mengunggah debug logs karena tooling dapat mencetak environment lokal.

APK final lokal: `build/app/outputs/flutter-apk/app-debug.apk`, **164.614.516 byte**.
SHA256: `F23599BC851448369E4BE46EB820E6798C1D4B9EE761C8BAEADFBE3E2945CF3E`.
APK tidak dikomit. Warning KGP dependency Firebase dan Java unchecked operations
masih muncul, tanpa kegagalan build; dependency/signing tidak diubah pada fase ini.

Startup emulator sempat tertunda oleh proses Java emulator sisa pengujian
sebelumnya pada port 8080. Command line diverifikasi berisi rules worktree ini
sebelum proses tersebut dihentikan; pengulangan final lulus seluruh 28 tests.
Pada percobaan awal satu assertion jumlah hasil query diperbaiki dari 41 ke 42:
filter teknisi tidak membatasi customer, sesuai aturan akses existing. Rules
menggunakan dispatch role/transisi dan pemeriksaan terminal lebih awal untuk
membatasi evaluasi cabang aturan yang tidak relevan.

Tes repository baru menjalankan repository asli dengan fake Firestore: completed
only, role scope, vehicle/service/date filter, batas tanggal WIB, cursor pada tanggal
yang sama, snapshot harga/nama, biaya jasa wajib sebelum completion, revisi stale,
reversal bersih dan seluruh 43 baris detail lintas tiga halaman. Fake Firestore
bukan bukti keamanan backend; suite emulator memakai SDK Firestore sesungguhnya.

Tes widget baru menjalankan filter → halaman 2 → perubahan filter → kembali
halaman 1 → detail total Rp130.000, di 320dp dan text scale 1,3. Loading, empty,
error/retry, cache serta direct link SO belum selesai diuji. Regresi booking dan
pekerjaan teknisi tetap dijalankan; pencarian tombol disesuaikan dengan tambahan
timeline/scroll. Snackbar sukses dari role sebelumnya dibersihkan dalam tes sebelum
tap tombol bawah agar benar-benar menerima pointer.

Rules tests menambah pricing integer/bounds/admin-only, snapshot nama palsu ditolak,
completion tanpa biaya jasa ditolak, terminal fields tidak bisa diubah, completed
query dengan scope/date/filter/cursor, customer/technician isolation dan larangan
usage/reversal terlambat. Seluruh suite Auth, booking, SO dan inventory lama ikut
dijalankan, termasuk concurrency stock/assignment yang sudah ada.

## Batas verifikasi

Rules/indexes production **belum dideploy**; operator perlu review PR, deploy
bersama, tunggu indeks siap, lalu acceptance dua akun/perangkat nyata. Emulator
tidak memvalidasi kesiapan indeks production. Completed SO lama dengan completedAt
null/tidak ada tidak dipaksakan masuk query tanggal; perbaikan data hanya melalui
operator tepercaya setelah audit, bukan input riwayat pelanggan.

Detail membaca seluruh snapshot sparepart on demand, biaya baca proporsional
jumlah baris; list tetap 20. Halaman penuh dapat menawarkan halaman kosong
berikutnya. Data baru saat pagination live dapat mengubah isi halaman; reset filter
atau buka ulang daftar untuk memulai dari terbaru. Cache native/offline setelah
process kill dan E2E pada perangkat fisik belum diuji dalam fase ini.

Native iOS **NOT VERIFIED**, host Windows tanpa Mac/Xcode. Konfigurasi Firebase
iOS dan native simulator build harus diverifikasi di Mac. Tidak ada klaim rilis
signed, smoke Android native fase ini, atau deploy produksi. Review manusia
sebelum merge; tidak ada auto-merge atau push ke upstream.
