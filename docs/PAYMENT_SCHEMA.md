# Phase 06: invoice, pembayaran dan laporan

Firebase Spark, Auth + Firestore saja. Kasir diprovision sebagai `users.role=admin`
oleh operator tepercaya; pelanggan/teknisi tidak dapat menaikkan role sendiri.
Tidak ada integrasi bank, gateway, Functions, Storage atau billing upgrade.

## Schema

`invoices/{serviceOrderId}`: satu invoice permanen per SO, nomor `INV~{SO ID}` unik
secara struktural, bukan nomor urut fiskal. SO harus completed dengan laborPrice
integer. Nomor tidak digunakan ulang setelah void/refund.

| Field | Arti |
| --- | --- |
| invoiceNo, serviceOrderId, customerId | Identitas dan ownership immutable |
| serviceName, vehiclePlate, laborPrice | Snapshot SO selesai |
| parts | Sampai 100 baris partUsages termasuk reversal, harga jual original; tanpa harga beli |
| partSubtotal, subtotal | Net part; jasa + net part |
| discount, fee, grandTotal | Penyesuaian disahkan admin; subtotal - diskon + biaya |
| paidAmount, change, due | Pembayaran net; kembalian cash kumulatif; sisa tagihan |
| status | unpaid, partial, paid, void, refunded |
| method | none, cash, transfer (verifikasi manual) |
| recordedBy, notes | Petugas dan catatan aksi terakhir |
| paidAt | Timestamp server saat pelunasan; dipertahankan setelah refund |
| createdAt, updatedAt, revision, lastKey | Timestamp server dan koordinasi transaksi/audit |

`invoices/{SO ID}/payments/{idempotencyKey}` adalah event immutable: key, revision,
kind (issued/payment/void/refund), amount (uang diterima/dikembalikan), applied
(alokasi tagihan; negatif untuk refund), change, method, notes, recordedBy, paidAt.
Event issued memakai key `issued`. Revisi mulai 0, naik tepat satu per aksi.
Tidak boleh update/delete snapshot invoice atau event. Perubahan saldo dan event
audit harus atomik. Alasan diskon/biaya disimpan permanen pada event issued.

Semua uang integer rupiah. Harga satuan/jasa/diskon/biaya 0..1 miliar;
total/uang masuk maksimal 9 kuadriliun (di bawah batas integer presisi JS).
Total invoice harus positif. Harga master terbaru tidak dipakai untuk cetak ulang.

## Transisi dan idempotensi

- unpaid -> partial/paid melalui pembayaran positif; partial -> partial/paid.
- Tunai bisa lebih dari sisa; selisih menjadi kembalian, bukan omzet.
- Transfer tidak boleh melebihi sisa, diperiksa manual sebelum konfirmasi.
- Void hanya unpaid. Refund manual penuh hanya partial/paid setelah uang dikembalikan.
- Void/refunded terminal, due=0. Refund mengurangi paidAmount ke 0 dan mencatat
  nominal pengembalian penuh. Partial refund tidak termasuk scope.
- ID invoice deterministik mencegah invoice kedua. Payment key dibuat sekali
  untuk operasi, dipertahankan setelah error untuk retry. Key yang sudah ada
  hanya diterima jika kind/amount/method/notes/actor sama; revisi stale ditolak.
- Rules dapat menolak salah satu transaksi serentak sebelum retry SDK. Repository
  membaca event dari server sesudah error dan hanya mengakui sukses jika payload
  identik. Tidak membuat write kedua untuk replay.
- Konfirmasi UI wajib untuk issue, payment, void dan refund; security tetap rules.

Rules memverifikasi admin aktif/email verified, ownership pelanggan, SO completed,
snapshot identitas/jasa, invariant total dan perubahan saldo/event atomik.
Pelanggan hanya membaca invoice/event miliknya; teknisi tidak membaca pembayaran.
Rules tidak dapat melakukan fold atas daftar part dinamis. Saat issue, admin
tepercaya mengesahkan snapshot part dan subtotal yang dihitung repository dari
ledger immutable. Batas client-only Spark: admin dengan client modifikasi dapat
mengesahkan partSubtotal awal berbeda; sesudah issue snapshot terkunci.
Rekonsiliasi ledger oleh operator tetap diperlukan. Diskon/biaya tidak memiliki
approval dua orang terpisah. Catatan jangan berisi nomor rekening lengkap.

## Query, periode dan biaya

Invoice list filter createdAt `[from, until)`, pelanggan ditambah customerId;
20 dokumen per halaman dengan startAfterDocument. Detail satu listener invoice;
audit dibaca per halaman 20. PDF memakai `pdf` + `printing`, font Noto Sans OFL
dibundel; tidak memerlukan unduh font. PDF dibuat dari metadata saat dibuka,
dicetak atau dibagikan melalui share sheet OS, tanpa upload ke Firebase.

Laporan hanya admin, dimuat lewat tombol, maksimal periode 31 hari:
booking menurut createdAt, SO completed menurut completedAt, omzet invoice
status paid menurut paidAt, pemakaian part net dari delta movement terkait SO,
dan jumlah SKU aktif lowStock saat ini. Berbagai satuan part dijumlahkan sebagai
unit operasional, bukan jumlah jenis atau nilai penjualan. Omzet bukan laba;
harga beli, beban operasional dan laba tidak dihitung. Partial/unpaid tidak masuk.
Refund penuh dikeluarkan dari omzet periode pelunasan, bukan jurnal arus kas pada
tanggal refund; laporan historis dapat berubah setelah refund.

Query tanggal/status difilter di Firestore lalu dijumlahkan dari halaman 20
dokumen. Tidak ada koleksi report yang bisa ditulis client. Read laporan sebanding
jumlah booking + SO selesai + invoice lunas + movement periode + SKU stok menipis;
halaman penuh memerlukan satu query kosong terakhir. Batas periode tidak membatasi
jumlah dokumen pada bengkel ramai. Ini bukan snapshot akuntansi lintas-query atomik;
jalankan ulang ketika transaksi berubah. Tidak ada biaya layanan berbayar baru;
kuota gratis tetap harus dipantau dan dapat habis. Usage/biaya project aktual tidak
diklaim karena console produksi tidak diperiksa.

Timestamp UTC, tampilan dan batas hari WIB UTC+7 terlepas timezone perangkat.
Index tambahan: customerId + createdAt desc, status + paidAt asc; laporan SO dan
stok memakai index fase sebelumnya. Index parts pada invoice dikecualikan karena
tidak pernah di-query, mengurangi index entries snapshot.

## Acceptance native dan deploy

Review/deploy rules dan indexes bersama, tunggu index READY sebelum production.
Perubahan ini tidak deploy Firebase atau mengubah billing. Android: buka invoice,
cetak preview dan share ke aplikasi lokal; uji partial, pelunasan tunai dengan
kembalian dan transfer manual memakai dua akun. iOS harus di Mac/Xcode dengan
konfigurasi Firebase iOS asli, native build dan buka/cetak/share PDF termasuk
popover iPad. Unit PDF atau APK tidak membuktikan plugin native iOS bekerja.
