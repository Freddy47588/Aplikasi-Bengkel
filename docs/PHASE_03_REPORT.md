# Phase 03 — Technician and Service Order management

Tanggal: 15 Oktober 2026 (Asia/Jakarta). Repo `Freddy47588/Aplikasi-Bengkel`.
Base `3e5b1f9`, Phase 02 merged melalui PR #3. Branch
`feat/technician-service-orders`. Berhenti pada Phase 03.

## Pre-flight

Fetch origin dan fast-forward local main berhasil. Checkout lama mengandung dua
file kosong untracked `1.3` dan `customer`, dipertahankan tanpa dihapus/stash.
Implementasi dikerjakan di worktree baru `Aplikasi-Bengkel-technician` dengan
working tree awal bersih. Tidak ada AGENTS.md yang berlaku. Remote tetap fork.
Audit mencakup Booking/Vehicle/users, auth session, Riverpod dan rules Phase 02.

## Perilaku dan schema

- Admin mengelola `technicians/{uid}`: nama, spesialisasi teks, active, available.
  Pencarian awalan nama peka huruf besar/kecil, filter active dan spesialisasi
  persis dijalankan pada query server, bukan hanya halaman yang dimuat.
  Daftar teknisi dan SO memakai cursor 20 dokumen, sebelumnya/berikutnya,
  stream realtime per halaman, loading/empty/error/retry. Halaman penuh terakhir
  dapat menawarkan satu halaman kosong berikutnya. Cursor memakai urutan stabil
  createdAt + ID (SO) atau nama + ID (teknisi).
- Role `technician` di `users/{uid}` tetap diprovision operator terpercaya melalui
  Admin SDK/Console. Client admin tidak dapat mengubah role atau active akun users.
  Active operasional teknisi terpisah dari active akun; keduanya diverifikasi
  saat assignment. Admin hanya mendapat tambahan get profil users bertipe teknisi,
  bukan izin enumerate users atau membaca profil pelanggan lain.
- SO dibuat admin dari booking confirmed saja. `serviceOrders/{bookingId}` adalah
  ID canonical permanen; tidak bisa memakai ID lain, overwrite, delete, atau
  membuat SO kedua setelah completed/cancelled. Snapshot customer, vehicle,
  service, keluhan dan jadwal harus sama dengan booking melalui rules getAfter.
- `technicians.currentOrderId` adalah lock kapasitas satu. Assignment/reassignment
  mengubah SO dan lock lama/baru atomik. Teknisi active, available dan akun aktif
  dengan role tepat diperlukan. Retry assignment ke teknisi yang sama tidak
  mengubah revision/event. Revisi yang berbeda ditolak untuk mencegah overwrite
  keputusan yang sudah berubah. Reassignment hanya queued/assigned/paused;
  pekerjaan inProgress harus dijeda dahulu. Terminal SO melepas lock atomik.
- SO memiliki status enum, revision, actor (`createdBy`, `updatedBy`, `assignedBy`),
  timestamps server (`createdAt`, `updatedAt`, `assignedAt`, `startedAt`,
  `completedAt`). `startedAt` menyimpan awal pertama, termasuk setelah reassign.
  Setiap mutasi wajib menulis event immutable `events/{revision}` pada transaksi
  yang sama, berisi actor, waktu, kind, status dan technicianId.
- Teknisi hanya query/read SO sendiri. Kendaraan/keluhan tersedia melalui snapshot
  SO; tidak diberikan akses umum kendaraan atau booking. Checklist tiga boolean,
  diagnosis/tindakan maksimal 2000 karakter, catatan maksimal 4000 karakter.
  Form menyimpan dengan revision saat dibuka; konflik meminta pengguna membuka
  ulang, tidak menimpa pekerjaan lebih baru. Catatan kerja terlihat juga oleh
  pelanggan pemilik SO: jangan masukkan informasi internal yang bersifat rahasia.

| Actor | Transisi |
| --- | --- |
| Admin create | confirmed booking → queued SO |
| Admin assign/reassign | queued/assigned/paused → assigned |
| Teknisi sendiri | assigned/paused → inProgress |
| Teknisi sendiri | inProgress → paused atau awaitingApproval |
| Admin review | awaitingApproval → completed atau assigned (perbaikan) |
| Admin cancel | semua status nonterminal → cancelled |

Teknisi hanya dapat menyimpan catatan saat inProgress/paused (termasuk saat
transisi yang diizinkan). Finish mengajukan awaitingApproval, wajib checklist
lengkap serta diagnosis/tindakan berisi. Admin menyetujui completed. Completed
dan cancelled immutable. Tidak ada self-assignment, promosi role atau pengeditan
snapshot/assignment oleh teknisi.

Customer hanya membaca progres miliknya. Booking tidak boleh dibatalkan customer
setelah SO ada (termasuk terminal), agar tidak berlawanan dengan progres servis.
Pembatalan SO oleh admin tidak mengubah booking/slot Phase 02; booking tetap
confirmed sebagai sumber historis. SO dan booking adalah dua state machine
terpisah; kapasitas booking tetap kapasitas satu per jam seperti Phase 02.

## Sumber Phase 04 dan Phase 05

SO menyimpan `bookingId`, `vehicleId`, `customerId`, `serviceId`, snapshots,
teknisi, diagnosis, tindakan, checklist, catatan, completion time dan event audit.
Phase 04 dapat mereferensikan SO canonical untuk ledger part; belum ada stok,
pemakaian part, transaksi inventori atau placeholder angka palsu. Phase 05 dapat
memproyeksikan SO completed sebagai riwayat; belum membuat koleksi riwayat.
Dashboard teknisi yang semula demo diganti daftar pekerjaan nyata. Tidak ada
Functions, Storage, upload, billing upgrade atau data seed produksi.

## Pengujian dan batas

| Pemeriksaan | Hasil |
| --- | --- |
| flutter pub get | PASS, tanpa dependency baru |
| flutter analyze | PASS, No issues found |
| flutter test | PASS, 38 tests (32 existing + 4 repository + 2 widget baru) |
| npm ci --no-audit --no-fund | PASS, 693 packages dari lockfile existing |
| npm run test:rules | PASS, 16 tests Auth + Firestore emulator; 0 fail |
| flutter build apk --debug | PASS; APK di build/app/outputs/flutter-apk/app-debug.apk |
| git diff --check | PASS |
| iOS native | NOT VERIFIED, Windows tanpa Mac/Xcode |
| E2E produksi / perangkat fisik | NOT RUN |

Unit tests memakai repository Firestore asli dengan fake database: confirmed-only,
double SO, nonactive/busy tech, retry assignment idempotent, stale revision,
reassignment melepas lock lama, ownership, pause/resume, checklist finish,
admin approval, timestamps/audit dan pagination 45 SO. Widget test menjalankan
start pekerjaan → catatan kerja → customer realtime progress di layar 320dp,
scroll form, serta loading/empty/error/retry. Pengujian layout existing pada
320/360/390/430/1280dp dengan text scale 1.3 tetap lulus.

Rules tests memakai request langsung, bukan mengandalkan validasi repository:
snapshot dan status palsu, extra fields, trusted role, larangan mencuri/melepas
lock sendiri, assignment bersamaan dengan satu pemenang, reassign tanpa release,
teknisi B tidak dapat mengubah tugas A, field/timestamp/actor immutable,
transisi invalid, audit wajib, approval/terminal release dan realtime owner query.
Race cancel booking vs create SO menghasilkan tepat satu commit. Seluruh test
Phase 02 tetap lulus; tak ada data test yang ditulis ke project produksi.

Review mandiri meninjau write allowlists, field ownership, access-call budgets,
getAfter lock/event invariants, stale edits, session logout, serta query/index
parity. Tidak ada temuan blocking yang masih terbuka. PR tetap membutuhkan review
manusia; tidak ada auto-merge atau force push.

Build menampilkan warning plugin Firebase mengenai Kotlin Gradle Plugin dan
unchecked Java operations yang sudah ada pada dependency; build berhasil tanpa
mengubah dependency atau signing. Saat pengulangan emulator, satu proses Java
lokal tertinggal pada port 8080; command line diverifikasi menunjuk worktree ini,
lalu proses tersebut dihentikan dan suite 16 tests dijalankan ulang dengan sukses.
Log/cache/APK tetap lokal dan diabaikan Git.

## File utama

- Domain/repository: `lib/core/models/service_order.dart`,
  `lib/core/data/service_order_repository.dart`, guard pembatalan pada
  `lib/core/data/firestore_booking_repository.dart`.
- UI/routing: `lib/features/technician/presentation/` (daftar teknisi, SO, detail,
  editor kerja dan pengganti dashboard demo), `lib/app/router/app_router.dart`,
  `lib/core/widgets/foundation_pages.dart`, `live_dashboard.dart`,
  `mobile_navigation.dart`.
- Backend: `firestore.rules`, `firestore.indexes.json`.
- Tests: `test/service_order_repository_test.dart`,
  `test/service_order_widgets_test.dart`, `test/test_support.dart`,
  `test_rules/service_orders.test.cjs`.
- Dokumentasi: README, PHASE_STATUS, ROADMAP, FIREBASE_SETUP dan laporan ini.

Rules/indexes belum dideploy ke project produksi. Review PR dahulu, lalu operator
deploy dan provision akun asli sesuai FIREBASE_SETUP.md. Composite indexes
mencakup query SO sesuai role dan kombinasi filter direktori teknisi. Firestore
emulator menguji rules; emulator tidak membuktikan kesiapan composite indexes
produksi. Setelah deploy, smoke semua filter dan halaman berikutnya sampai indeks
READY, dua perangkat serta pemulihan jaringan/restart dengan akun asli.

Native iOS **NOT VERIFIED**: host Windows tanpa Mac/Xcode; konfigurasi Firebase
iOS asli masih merupakan batas Phase 02. Android build bukan bukti acceptance
perangkat fisik. Tidak ada klaim E2E produksi atau native iOS.
