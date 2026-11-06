# UI Refinement 01: inventori, detail stok, dan riwayat

Tanggal: 6 November 2026. Baseline source: `50bc95b1574e65793f7b9b6405194631f43f6fb3`
di `main`. HEAD dan `origin/main` sama setelah fetch sebelum implementasi.
Working tree awal mempunyai tujuh file registrasi plugin desktop yang ditandai
modified; semuanya dikecualikan dari commit refinement ini.

## Bukti visual

Render widget Flutter aktual, viewport **390 × 844dp**, device pixel ratio 2,
PNG **780 × 1688px**, text scale 100%, font Roboto dan Material Icons dari SDK.
Database fake hanya digunakan dalam test harness; kode production tetap
mengambil data melalui provider dan repository existing. Fixture dibuat melalui
repository dengan stok, SKU, dan harga yang berbeda dari mockup. Timestamp
fixture ditetapkan agar before/after dapat dibandingkan.

| Layar | Before | After |
| --- | --- | --- |
| Inventori Sparepart | [Before](before/fixture-refinement-inventory.png) | [After](after/fixture-refinement-inventory.png) |
| Detail Stok | [Before](before/fixture-refinement-stock-detail.png) | [After](after/fixture-refinement-stock-detail.png) |
| Riwayat Stok | [Before](before/fixture-refinement-stock-ledger.png) | [After](after/fixture-refinement-stock-ledger.png) |

Before diambil sebelum perubahan screen production. After diperiksa visual lalu
diulang setelah memperkecil hero dari 144 ke 128dp, mengubah filter dari lingkaran
ke rounded rectangle, dan menyatukan ringkasan ledger dengan area expand.
Capture memakai screen sebagai root route: detail/ledger tidak memperlihatkan
back button otomatis, dan navigasi inventori menyorot default Beranda. Pada
alur aplikasi sebenarnya, detail/ledger dibuka dengan `Navigator.push` sehingga
back button tersedia; `navigationIndex` existing tetap menyorot Bengkel untuk
route `/admin/inventory`. Status bar, bingkai ponsel, dan panel poster tidak dibuat.

### Perbandingan terhadap mockup

| Aspek | Perubahan dan hasil pengamatan |
| --- | --- |
| Komposisi inventori | AppBar putih dan judul terpusat; toolbox, deskripsi, search/filter sejajar, kartu ringkas, CTA tambah biru. Kartu pertama bergeser dari sekitar y=510dp ke y=336dp. Lima kartu fixture kini setidaknya terlihat sebagian, dibanding satu kartu penuh pada baseline. |
| Ukuran dan spacing | Padding horizontal 16dp; jarak kartu 8dp; hero inventori/ledger 128dp; detail 156dp. Semua konten tetap dapat di-scroll, termasuk pagination dan aksi tambahan. |
| Tipografi | Roboto existing dipertahankan. Nama item lebih tebal, nama produk dipusatkan, SKU dipisahkan sebagai identitas. Bentuk huruf berbeda dari lettering mockup; tidak ada klaim identik pixel. |
| Detail stok | Informasi yang sebelumnya tersebar di beberapa section disatukan dalam kartu dengan ikon dan divider. CTA Masuk/Keluar ditampilkan sebagai pasangan; pada lebar sempit atau text scale besar ditumpuk. |
| Riwayat | Ringkasan tipe, delta, unit, waktu, SKU, dan alasan selalu terlihat. Masuk memakai hijau/panah turun, Keluar merah/panah naik, Koreksi biru/sync; Reversal tetap tipe tersendiri. Saldo, aktor, SO, referensi reversal, dan aksi reversal tersedia dengan expand kartu. |
| Ilustrasi | Toolbox, oil, ledger, dan wave existing diaudit. Aset transparan biru/putih dengan aksen amber sudah relevan. Tidak dibuat aset baru. Bentuk toolbox dan clipboard tidak sama persis dengan gambar referensi. |
| Warna | Steel Navy `#1E3A5F`, Royal Blue `#2563EB`, background `#F8FAFC`, aksen amber existing. Foreground status memakai warna gelap agar terbaca pada tint status. |

## Mapping fungsi dan penyimpangan yang disengaja

- `InventoryScreen`: `inventoryPageProvider`, filter awalan SKU, kategori tepat,
  aktif/nonaktif, stok minimum/habis, refresh, pagination, pemilihan sparepart SO,
  detail, dan pembuatan master tetap tersedia. Filter dibuka tombol terpisah;
  pencarian dikirim melalui keyboard search, ikon submit, atau tombol terapkan.
  Menu AppBar menyediakan refresh dan akses riwayat global.
- CTA tambah dipindah dari AppBar ke tombol biru berlabel. Hanya admin yang
  mendapat CTA ini. Navigasi bawah existing dipertahankan; akibatnya ruang daftar
  lebih pendek daripada mockup yang tidak memperlihatkan navigasi bawah.
- Badge dihitung dari stok dan minimum aktual: nol = Habis, `stock <= minimumStock`
  = Minimum, selebihnya Aman. SKU diarsipkan tetap diberi Nonaktif, bukan Aman.
  Query low-stock existing tetap memakai field `lowStock` yang dikelola transaksi.
- `SparepartDetailScreen`: `sparepartProvider(sku)` tetap sumber data. Kategori,
  stok, minimum, harga jual, dan harga beli dipertahankan. Supplier muncul hanya
  jika tercatat. Harga beli dan operasi tambahan membuat detail lebih panjang
  daripada mockup. Produk non-oli memakai ilustrasi sparepart umum existing.
- Masuk membuka form existing dengan `MovementKind.receipt`; Keluar dengan
  `MovementKind.usage`. Keluar tetap wajib SO aktif sesuai repository/rules;
  tidak ditambahkan pengeluaran bebas SO. Dalam konteks pemakaian SO, penerimaan
  stok dinonaktifkan dan pilihan transaksi tetap terkunci pada usage.
- Koreksi tetap tersedia melalui Catat transaksi stok / koreksi dan dropdown
  transaksi existing. Edit/arsip serta riwayat tetap dapat diakses. Master arsip
  menonaktifkan transaksi baru; reversal yang sah tetap diakses melalui ledger.
- `StockLedgerScreen`: `ledgerPageProvider` dan cursor existing dipertahankan.
  Search adalah SKU lengkap, bukan pencarian bebas keterangan. Filter SO memakai
  query repository yang sudah tersedia. Filter dari layar SKU/SO tertentu tetap
  terkunci pada scope pemanggil. Penerapan filter mengembalikan cursor ke halaman 1.
  Tidak dibuat filter tipe lokal yang hanya menyaring halaman aktif.
- Repository, model, transaksi/idempotensi, router, provider, Firebase Auth,
  Firestore rules/indexes, data production, dan integrasi notifikasi tidak diubah.
- Wave existing hanya 32dp dan menempati ruang tersendiri di bawah area scroll;
  tidak menjadi overlay konten. Wave disembunyikan oleh WorkshopBody ketika
  keyboard terbuka.

## Validasi

Hasil final quality gate dicatat setelah suite selesai. Log lokal berada pada
`build/inventory-refinement-*.log` dan tidak dimasukkan ke Git.

- Format check: `dart format --output=none --set-exit-if-changed lib test`;
  81 file, 0 perubahan.
- `flutter analyze`: no issues found.
- `flutter test`: 110 test lulus, 0 gagal.
- `flutter build apk --debug`: berhasil, `assembleDebug` 167,7 detik.
  SHA-256 APK: `7614a7c71c9078809471557c98fc6a67800bc3adb254fdaad7c647c517786397`.
  Toolchain masih mengeluarkan warning kompatibilitas KGP plugin Firebase;
  tidak ada upgrade dependency dalam pekerjaan visual ini.
- Seluruh `test_rules/*.test.cjs`: **38 lulus, 0 gagal**, termasuk integrasi
  Phase 07, transaksi stok, batas stok, role, isolation, dan histori immutable.
  Emulator terpisah memakai `demo-bengkelku`, Firestore `127.0.0.1:18080`, Auth
  `127.0.0.1:19099`, hub 14400, dan logging 14500. Rules/indexes disalin identik
  ke folder build untuk konfigurasi lokal. Emulator existing pada port default
  tidak dihentikan atau di-reset. Tidak ada deploy production.
- Test baru mencakup tiga layar pada 320/360/390/430dp dan skala 100/130/200%,
  ambang status stok, transaksi melalui dua CTA, validasi SO wajib, pencarian SKU,
  filter SO, pagination, reset cursor, dan reversal melalui kartu expanded.
  Test existing tetap mencakup arsip, retry/idempotensi, pembatasan role, serta
  navigasi. Ini validasi widget/repository/emulator; bukan bukti pengujian
  perangkat fisik Android atau iOS. iOS build tidak dijalankan pada host Windows.

Regenerasi after:

```powershell
flutter test test/inventory_refinement_test.dart --plain-name "inventory refinement renders three current screens" --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/screenshots/inventory-refinement-01/after
```

## Delivery Gate antislop

- Hard Gate PASS: kontrol memakai callback aktual; data dinamis dari provider;
  loading/error/empty state dipertahankan; 36 kombinasi layar/lebar/skala diuji.
  Kontras dihitung dengan rumus WCAG: navy/background 10,99:1, putih/Royal Blue
  5,17:1, muted/putih 7,58:1, status success 5,95:1, minimum 5,73:1, habis 5,29:1,
  koreksi 5,57:1 pada tint 12% di atas putih. Border input 4,76:1 terhadap putih.
- Purpose Gate PASS: ikon kotak menunjukkan inventori, ikon arah menjelaskan
  perubahan stok, kartu tipis memisahkan record, badge menjelaskan status, biru
  menandai aksi utama. Wave kecil mengulang motif referensi; tanpa shadow/glow baru.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1. Arah visual diambil dari mockup:
  ilustrasi alat bengkel menjadi focal point, jarak membedakan hero/filter/data,
  amber terbatas pada ilustrasi dan status minimum, tanpa animasi dekoratif baru.
- Craftsmanship PASS: before/after ditinjau dan diperbaiki; form dan operasi
  existing digunakan kembali; aksesibilitas memakai kontrol Material native,
  label/tooltip, status teks, reflow, serta state disabled. Tidak ada dummy
  production, testimoni, klaim pemasaran, route palsu, atau fitur yang dihapus.

## Status final

Quality gate lulus: format, analyze, 110 Flutter tests, 38 rules/emulator tests,
dan build APK debug. Commit hanya memuat dua source UI inventori, tiga file test,
serta laporan dan enam screenshot di folder ini. Perubahan registrasi plugin
desktop existing dibiarkan pada working tree. Tidak memulai Phase 08.
