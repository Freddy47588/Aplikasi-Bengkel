# Audit UI/UX Phase 06.5

Base: `12583b2` (`origin/main`, Phase 01–06). Audit dan implementasi pada
2 November 2026 (Asia/Jakarta), branch `refactor/ui-ux-polish`.

| Temuan | Perbaikan |
| --- | --- |
| Dashboard berupa teks panjang/tombol polos | Hero role, kartu metrik terbatas data, kartu aksi, progres, kendaraan dan riwayat terbaru |
| Dashboard teknisi sama dengan daftar order | Beranda tersendiri: pekerjaan aktif/selesai pada halaman, prioritas, akses jobs/riwayat |
| Profil placeholder | Email, role, status aktif/verifikasi dari auth session, reset password, akses kendaraan/invoice customer |
| Detail booking customer menyorot Riwayat | Daftar/detail masuk area Booking, diuji termasuk system back |
| Inventory/order/invoice memilih Beranda secara fallback | Mapping area Bengkel/Servis eksplisit, tautan antarhalaman dan nav pembayaran |
| Pembayaran/invoice padat | Bagian identitas/status, biaya, total/saldo, PDF, tindakan admin dan audit dipisahkan |
| Filter inventory terlalu teknis | Label kode sparepart/kategori, contoh awalan, nama item utama, SKU/kategori tetap tersedia |
| Riwayat meminta ID kendaraan/servis | Dropdown nama/plat dan jenis servis; kendaraan arsip dan jenis servis nonaktif dari snapshot halaman tetap dapat difilter |
| Riwayat menampilkan status pembayaran statis | Baca dokumen invoice sesuai SO, realtime, loading/error/retry/cache; tidak membaca invoice untuk teknisi |
| Form booking masih menyebut kendaraan demo | Instruksi kendaraan akun dan jadwal WIB |
| Identifier teknis mendominasi detail | Nama kendaraan/plat/layanan/teknisi sebagai label, referensi riwayat dalam disclosure |
| Layar lebar/form/dialog tidak seragam | WorkshopBody 960dp, grid alami, input bertema, dialog scrollable, spacing dan tombol sentuh bersama |
| Error pada beberapa layar berupa tombol polos | LoadError/RetryLoad reusable, penjelasan koneksi dan aksi retry |
| Identitas logo belum seragam | Emblem hex rotor baru, adaptive icon, native splash Android/iOS, header PDF |

## Batas data dan keputusan UX

Ringkasan dashboard tidak menghitung total seluruh bengkel dari query terbatas.
Booking maks.100, order halaman terbaru maks.20, kendaraan aktif maks.50. Hasil
inventory stok rendah diberi keterangan terbatas per halaman. Omzet ada di
laporan on-demand existing, dengan definisi dan periode yang tetap terlihat.

Pencarian inventory tetap mengikuti kemampuan repository existing (awalan SKU,
kategori persis). Label menjelaskan kemampuan itu tanpa mengklaim pencarian
nama/full-text. Dropdown kendaraan customer memakai query kepemilikan existing
termasuk arsip, maksimum 50. Admin/teknisi memilih kendaraan dari halaman
riwayat yang sedang dimuat; keterangan batas ini ditampilkan. Pencarian semua
kendaraan lintas halaman memerlukan desain query/index tersendiri dan bukan
perubahan diam-diam pada fase UI.

Status invoice di riwayat dibaca lewat ID deterministik existing (ID SO).
Metadata Firestore cache dibedakan dari status server. Teknisi mendapatkan
pesan pembayaran dikelola kasir; tidak mengeluarkan query invoice terlarang.
Referensi transaksi/petugas, biaya snapshot, reversal dan audit tetap tersedia.

Tidak mengubah business logic, schema, security rules, role/permission atau
Firebase project. `invoice_pdf.dart` hanya berubah untuk header brand.

## Bukti dan batas verifikasi

Widget suite mempertahankan pengujian booking, assignment, work checklist,
inventory idempotency, pembayaran/invoice dan rules existing. Ekspektasi label
yang berubah diperbarui untuk memeriksa UX baru; tes tidak dihapus.
Suite baru menambah dashboard tiga role, route tambahan, data realtime,
keyboard, password visibility, cache, pembatasan invoice teknisi, dan 320–800dp
pada skala teks 1,3×. Hasil final ada di `PHASE_06_5_REPORT.md`.

Raster widget yang dibuat dengan `--dart-define=CAPTURE_UI=true` adalah render
Flutter sebenarnya menggunakan fixture tes, bernama `fixture-*.png` di
`build/ui-ux-evidence/`. Itu bukan bukti login production atau screenshot
akun nyata. Screenshot emulator dari perubahan lokal sebelumnya disimpan sebagai arsip lokal, bukan bukti untuk palet final.
Tidak ada mockup atau screenshot rekayasa yang diklaim sebagai hasil aplikasi.
Tidak tersedia screenshot baseline yang terverifikasi untuk before/after.

Native iOS dan UAT akun Firebase tiga role memerlukan environment/akun uji
yang diotorisasi. Risiko backend existing dari laporan Phase 06 tetap berlaku;
tidak ada aturan transaksi yang dilemahkan untuk mempercantik UI.
