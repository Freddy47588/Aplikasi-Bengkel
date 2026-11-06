# Black-box results Phase 07

Pembaruan perangkat 6 November pada Infinix X6833B, Android 14, source 316b6ab,
dataset demo-bengkelku. BB-C07 PASS untuk kirim booking, BB-A01 PASS untuk
login/dashboard, BB-A15 PASS untuk laporan fixture Rp127.000. Pembatalan,
checklist, diagnosis/tindakan dan pause/resume telah diamati, tetapi kasus
lengkap dengan seluruh input negatif/retry yang belum dijalankan tetap NOT RUN.
Ringkasan terbaru 3 PASS, 33 NOT RUN, 1 BLOCKED. Actual dan bukti asli ada pada
[PHASE_07_DEVICE_RESULTS.md](PHASE_07_DEVICE_RESULTS.md). Tabel template di
bawah merekam status awal 5 November dan bukan hasil terbaru.

5 November 2026 WIB. Build/commit untuk sesi manual: belum diisi. Lingkungan:
`demo-bengkelku`, panduan akun/data pada TEST_DATA_GUIDE.md. Semua baris di bawah
adalah test case UI yang siap dijalankan. Actual result tidak diisi dari unit
test atau fixture screenshot. ADB kosong; belum ada penguji manual/UAT nyata.

Prasyarat umum: emulator hidup, seed tervalidasi, aplikasi debug mode emulator;
C/A/T = login customer/admin/technician. Bukti harus memuat ID kasus, perangkat,
waktu, commit, actual dan screenshot/log yang telah disanitasi. Tanda — berarti
belum ada bukti. Expected hasil negatif harus ditolak dengan error yang jelas.

| ID | Role | Fitur | Prasyarat | Input | Langkah | Expected | Actual | Status | Bukti |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| BB-C01 | Pelanggan | Register | Logout | email test baru/password valid | Daftar, buka profil | Role customer; verifikasi diminta | Belum dijalankan | NOT RUN | — |
| BB-C02 | Pelanggan | Login/logout | Akun verified | email/password; password salah | Login salah, benar, logout | Error salah; dashboard benar; sesi berakhir | Belum dijalankan | NOT RUN | — |
| BB-C03 | Pelanggan | Verifikasi | Akun unverified | kode OOB emulator | Buka verifikasi; refresh akun | Operasi dibatasi sebelum verified, terbuka sesudahnya | Belum dijalankan | NOT RUN | — |
| BB-C04 | Pelanggan | Reset password | Logout | email; kode reset; password baru | Forgot password, reset, login | Password lama ditolak, baru diterima | Belum dijalankan | NOT RUN | — |
| BB-C05 | Pelanggan | Kendaraan create/read | C | Honda; B 8123 QA | Tambah dan buka daftar | Tersimpan pada pemilik yang benar | Belum dijalankan | NOT RUN | — |
| BB-C06 | Pelanggan | Kendaraan edit/archive | C, kendaraan aktif | nama/plat baru | Edit, arsip, buka riwayat | Daftar aktif berubah; snapshot historis tetap | Belum dijalankan | NOT RUN | — |
| BB-C07 | Pelanggan | Booking | C, kendaraan aktif, slot kosong | layanan/jadwal/keluhan valid | Submit lalu buka detail | Pending dan satu slot aktif | Belum dijalankan | NOT RUN | — |
| BB-C08 | Pelanggan | Validasi/race booking | Dua customer, satu slot | input invalid; slot sama | Submit invalid; submit serentak | Invalid ditolak; satu pemenang | Belum dijalankan | NOT RUN | — |
| BB-C09 | Pelanggan | Cancel booking | C, pending tanpa SO | konfirmasi cancel | Batal; booking ulang slot | Cancelled dan slot bisa dipakai ulang | Belum dijalankan | NOT RUN | — |
| BB-C10 | Pelanggan | Tracking | C, SO sendiri | status diubah teknisi/admin | Buka tracking, ubah dari sesi lain | Status/event realtime benar | Belum dijalankan | NOT RUN | — |
| BB-C11 | Pelanggan | Riwayat/filter | C, completed | kendaraan/jenis/tanggal | Filter, buka detail | Riwayat sendiri, snapshot immutable | Belum dijalankan | NOT RUN | — |
| BB-C12 | Pelanggan | Invoice/PDF | C, invoice sendiri | unpaid/partial/paid | Buka invoice, PDF, share/cancel | Total/sisa benar; tidak ada aksi bayar admin | Belum dijalankan | NOT RUN | — |
| BB-C13 | Pelanggan | Isolasi akun | C lalu customer2 | path/route customer lain | Ganti akun, buka data sebelumnya | Tidak mengakses milik akun lain | Belum dijalankan | NOT RUN | — |
| BB-A01 | Admin | Login/dashboard | Logout | admin demo | Login; buka ringkasan | Route admin dan cakupan data jelas | Belum dijalankan | NOT RUN | — |
| BB-A02 | Admin | Booking | A, pending | confirm/reject | Kelola dua booking berbeda | Transisi sah; reject melepas slot | Belum dijalankan | NOT RUN | — |
| BB-A03 | Admin | Teknisi | A, akun teknisi trusted | UID/nama/spesialisasi | Tambah/edit available; arsip saat bebas | Direktori diperbarui; akun users tidak diubah | Belum dijalankan | NOT RUN | — |
| BB-A04 | Admin | Service Order | A, booking confirmed | booking ID | Buat SO dua kali | Satu SO canonical dan event created | Belum dijalankan | NOT RUN | — |
| BB-A05 | Admin | Assignment | A, SO queued, teknisi bebas | UID teknisi | Assign; coba assign SO lain | Satu currentOrderId; konflik ditolak | Belum dijalankan | NOT RUN | — |
| BB-A06 | Admin | Review/pricing | A, awaitingApproval | biaya jasa integer | Simpan harga; complete | SO/history/audit tersimpan; lock dilepas | Belum dijalankan | NOT RUN | — |
| BB-A07 | Admin | Sparepart master | A | SKU/nama/harga/minimum | Create, edit, archive | SKU unik, validasi integer, arsip historis aman | Belum dijalankan | NOT RUN | — |
| BB-A08 | Admin | Stock receipt/adjustment | A, SKU aktif | qty/reason | Receipt, koreksi, lihat ledger | Saldo/lowStock/revisi benar | Belum dijalankan | NOT RUN | — |
| BB-A09 | Admin | Stock usage/reversal | A, SO aktif, stok cukup | qty, reason | Pakai, retry, reversal penuh | Sekali decrement/reversal; audit immutable | Belum dijalankan | NOT RUN | — |
| BB-A10 | Admin | Approval request | A, request pending | approve/reject reason | Approve satu; reject lainnya | Approval atomik usage; reject tanpa stok | Belum dijalankan | NOT RUN | — |
| BB-A11 | Admin | Invoice issue | A, completed berharga | discount/fee/reason | Terbitkan, coba ulang | Satu invoice snapshot + issued audit | Belum dijalankan | NOT RUN | — |
| BB-A12 | Admin | Payment | A, unpaid/partial | tunai bertahap; lebih bayar | Bayar, retry, pelunasan | Partial/paid/sisa/kembalian benar; tidak ganda | Belum dijalankan | NOT RUN | — |
| BB-A13 | Admin | Transfer/void/refund | A, invoice sesuai status | nominal/reason | Overpay transfer; void unpaid; refund paid | Overpay ditolak; void/refund penuh terminal ber-audit | Belum dijalankan | NOT RUN | — |
| BB-A14 | Admin | PDF native | A, invoice | print/share/cancel | Preview cetak; pilih share target | Snapshot terbaca, tidak crash | Belum dijalankan | NOT RUN | — |
| BB-A15 | Admin | Laporan | A | periode WIB maksimal 31 hari | Muat; bandingkan ledger | Paid-only; fixture omzet Rp127.000 sebelum modifikasi | Belum dijalankan | NOT RUN | — |
| BB-A16 | Admin | CRUD katalog UI | A | layanan baru | Cari menu tambah/edit/arsip layanan | Kebutuhan CRUD UI belum tersedia | Audit source: operator Console; tidak ada UI | BLOCKED | README.md; QA-01 |
| BB-T01 | Teknisi | Login/tugas | Logout | teknisi demo | Login, buka daftar | Tugas sendiri, tidak ada data keuangan admin | Belum dijalankan | NOT RUN | — |
| BB-T02 | Teknisi | Detail/assignment | T | SO sendiri/lain | Buka detail; coba route SO lain | Snapshot sendiri terbaca; SO lain ditolak | Belum dijalankan | NOT RUN | — |
| BB-T03 | Teknisi | Checklist | T, inProgress | 3 checklist | Simpan, buka ulang | Nilai dan revisi/audit tersimpan | Belum dijalankan | NOT RUN | — |
| BB-T04 | Teknisi | Diagnosis/tindakan | T, inProgress | catatan valid/kosong/terlalu panjang | Simpan, submit invalid | Tersimpan valid; invalid ditolak | Belum dijalankan | NOT RUN | — |
| BB-T05 | Teknisi | Status | T, assigned/paused | start/pause/resume | Jalankan transisi | Status sah dan startedAt pertama tetap | Belum dijalankan | NOT RUN | — |
| BB-T06 | Teknisi | Request part | T, inProgress | SKU/qty/reason | Submit; tunggu admin | Pending; keputusan tampil; teknisi tidak mengubah stok | Belum dijalankan | NOT RUN | — |
| BB-T07 | Teknisi | Selesai | T, inProgress | checklist/diagnosis/tindakan | Ajukan selesai lalu admin approve | AwaitingApproval lalu completed; immutable | Belum dijalankan | NOT RUN | — |
| BB-X01 | Semua | Jaringan/lifecycle/font | Role aktif | offline, background, font besar | AND-08..11 | Error jelas, tidak crash/overflow/duplikasi | Belum dijalankan | NOT RUN | — |

Total template: 37 kasus, 36 NOT RUN dan 1 BLOCKED berdasarkan audit source.
Pengujian backend otomatis dilaporkan terpisah di PHASE_07_REPORT dan
SECURITY_AUDIT. PASS otomatis tidak mengubah status manual di tabel ini.
