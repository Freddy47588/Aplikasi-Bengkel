# Admin — Teknisi dan Service Order

Audit awal `d04c49ebd428016a8c96bffd5e550a95d011f588`, branch `main`.
HEAD dan origin/main sesuai setelah fetch. Working tree awal hanya berisi tujuh
generated plugin desktop yang sudah berubah; byte awal dicadangkan di
`build/refinement-04-local-backup`, tidak ditimpa atau disertakan dalam commit.
Tidak ada AGENTS.md yang berlaku pada repository ini.

## Mapping layar dan screenshot

| Mockup | Source aktual | Before | After |
| --- | --- | --- | --- |
| Data Teknisi | `TechniciansScreen`, editor operasional existing | [Before](before/fixture-admin-refinement-technicians.png) | [After](after/fixture-admin-refinement-technicians.png) |
| Daftar Service Order | Cabang admin `ServiceOrdersScreen` | [Before](before/fixture-admin-refinement-orders.png) | [After](after/fixture-admin-refinement-orders.png) |
| Detail Service Order | Cabang admin `ServiceOrderDetailScreen`, `AdminOrderDetail` | [Before](before/fixture-admin-refinement-order-detail.png) | [After](after/fixture-admin-refinement-order-detail.png) |

Gambar merupakan render widget Flutter pada 390 × 844dp, DPR 2, dengan font Roboto
dan Material Icons asli. Fixture FakeFirestore dibaca melalui provider dan
repository aplikasi. Nama, jumlah dan biaya uji hanya ada di test; source production
tidak memuat data contoh dari mockup. Ini bukti render otomatis, bukan screenshot
Infinix atau sesi Firebase produksi. ADB tidak menemukan perangkat terhubung.

## Audit perilaku

Model teknisi memuat nama, spesialisasi, active, available dan currentOrderId.
Tambah Teknisi tetap membuka profil operasional; akun Auth ber-role technician
harus disiapkan operator tepercaya. Edit, nonaktifkan dan sakelar menerima tugas
tetap memakai `saveTechnician`; teknisi yang masih memegang tugas tidak dapat
dinonaktifkan. Picker hanya mengizinkan teknisi aktif, tersedia dan tidak terkunci.

SO memiliki tujuh status: queued, assigned, inProgress, paused, awaitingApproval,
completed, cancelled. Assignment hanya dari queued/assigned/paused dan memakai
revision serta lock teknisi atomik. Admin tidak diberi tombol mulai/pause/resume
yang menjadi alur teknisi. Admin dapat membatalkan SO nonterminal; dari
awaitingApproval admin dapat menyetujui penyelesaian atau mengembalikan untuk
perbaikan. Penyelesaian memerlukan biaya jasa integer tersimpan, termasuk Rp 0.
SO terminal tetap tidak dapat diubah, tetapi invoice, histori dan catatan masih
dapat dibuka sesuai state existing.

Repository, model, rules, autentikasi, route dan transaksi tidak diubah. Audit event
dan pemeriksaan revision tetap dilakukan repository. Referensi penugasan, timestamp,
checklist, diagnosis, tindakan dan catatan tetap ada pada detail; section dapat
dibuka, bukan dihilangkan. Pelacakan lengkap existing tetap tersedia.

## Perbandingan visual dan perbaikan gap

Bagian di dalam ponsel menjadi referensi: header putih terpusat, ilustrasi teknisi
dengan gear serta clipboard/mobil, deskripsi, search/filter, kartu putih dengan
border biru muda, badge kanan dan CTA Royal Blue. Bingkai ponsel, jam, Dynamic
Island dan panel poster tidak ditiru. Ilustrasi `technician.png`, `checklist.png`
dan `wave.png` existing sesuai keluarga BengkelKu sehingga digunakan kembali.

Before memakai kartu tinggi, badge di bawah deskripsi dan timeline vertikal yang
menjauhkan detail biaya/sparepart. After memakai padding horizontal 16dp, kartu
radius 14dp, avatar ikon konsisten dan informasi utama yang lebih rapat. Badge
dipindahkan ke kanan; setelah render pertama batas lebar badge diperbaiki agar
tidak menyisakan ruang kosong di kanan. Spesialisasi dan ketersediaan teknisi
digabung satu baris yang tetap dapat membungkus.
Pada fixture 390dp, tiga kartu teknisi beserta CTA tambah terlihat penuh; before
hanya menampilkan dua kartu penuh tanpa CTA tambah di area bawah. Pada detail,
harga jasa, satu baris pemakaian dan empat tahap progres kini terlihat bersama
sebelum aksi utama, sedangkan before berhenti di tengah timeline vertikal.

Detail menyusun identitas SO, kendaraan, penugasan, pekerjaan/biaya, sparepart dan
timeline sebelum tindakan. CTA mengikuti state: assignment, persetujuan, atau
pencatatan biaya; pembatalan tetap outlined dan dikonfirmasi. Ringkasan sparepart
di-refresh setelah kembali dari halaman transaksi. Pada skala teks besar, header
bertambah tinggi, judul membungkus, badge pindah ke bawah judul dan timeline menjadi
vertikal. Ilustrasi disembunyikan di atas 1,3× mengikuti komponen form existing.

## Penyimpangan dari mockup

- Nomor SO memakai document ID aktual. Tidak dibuat format SO contoh yang tidak
  tersimpan. Nama pelanggan tidak ditambahkan karena list menggunakan snapshot SO.
- Deskripsi teknisi memakai spesialisasi dan ketersediaan aktual; tidak memalsukan
  jabatan atau avatar foto personal.
- Pencarian teknisi tetap prefix nama sesuai kapitalisasi Firestore; filter aktif
  dan spesialisasi serta pagination tetap tersedia. Pencarian/filter SO berlaku
  pada halaman yang dimuat (maksimal 20), bukan klaim pencarian global. Caption
  menjelaskan cakupan ini, dan tombol halaman tetap tersedia pada hasil kosong.
- Model menyimpan satu `laborPrice` untuk jasa SO. Tidak dipecah menjadi biaya
  per jenis servis palsu. Jika belum tersimpan, tertulis “Belum dicatat”.
- Ringkasan sparepart memakai name/SKU/quantity/unit/sellPrice snapshot pemakaian,
  dengan harga per unit eksplisit. Reversal ditandai “Dikembalikan” dan tetap
  terpisah dari pemakaian. Pagination memakai query ledger existing; tidak
  menampilkan total yang mengabaikan halaman berikutnya atau reversal.
- Empat tahap ringkas memakai status SO aktual: Antrean, Ditugaskan, Dikerjakan,
  Selesai. Dijeda/menunggu persetujuan/dibatalkan ditulis eksplisit. Tahap
  “Dikonfirmasi” mockup tidak ditambahkan sebagai status SO baru.
- Teks badge mengikuti tujuh status existing. Tidak meratakan semua state menjadi
  tiga label sehingga assignment, pause dan approval tetap dapat dibedakan.
- Menu Service Order memuat Kelola teknisi dan Muat ulang agar judul tetap terbaca.
  Navigasi bawah admin dan WorkspaceLinks existing dipertahankan; wave lebih tipis
  agar konten dapat digulir tanpa tertutup.
- Font Roboto dan aset existing mendekati referensi, bukan font/aset identik.
  Konten aktual yang lebih panjang dapat membutuhkan gulir.

## Validasi dan delivery gate

Test baru mencakup pencarian teknisi, edit/nonaktifkan, akses Tambah Teknisi,
penugasan dan lock teknisi, approval tanpa harga ditolak, harga negatif ditolak,
harga Rp 0 diterima, terminal menutup aksi mutasi, audit event, redirect nonadmin,
pencarian/filter SO, refresh ringkasan setelah pemakaian sparepart, dan semua tujuh
status. Tiga layar diuji pada 320/360/390/430dp dan text scaling 1/1,3/2× dengan
filter terbuka dan gulir ke bawah.

Log lokal di `build/admin-refinement-*.log`. Format check bersih (89 file),
`flutter analyze` tanpa issue, dan `flutter test --concurrency=1` lulus 126 tes.
Tes terarah setelah perbaikan header lulus 10 tes; capture ketiga layar juga lulus.
Percobaan gate paralel sebelumnya kehabisan memori (Flutter OOM, daemon Gradle dan
emulator berhenti), sehingga hasil tersebut tidak dipakai sebagai gate lulus.
Pengulangan dilakukan berurutan dengan satu worker Flutter dan heap emulator 1GB,
tanpa mengubah konfigurasi repository. Rules final lulus 38 tes, 0 gagal, native
exit code 0. `flutter build apk --debug` juga lulus, native exit code 0, dalam
154,1 detik. Plugin Firebase Auth/Core masih memberi warning KGP untuk Flutter
mendatang; dependency dan konfigurasi build tidak diubah. Rules diuji menggunakan demo project terisolasi pada
Firestore 18080/Auth 19099. Tidak ada production deploy atau reset data asli.
Uji perangkat fisik/Infinix serta build iOS belum dilakukan pada Windows.

APK final: `build/app/outputs/flutter-apk/app-debug.apk`, 216.323.573 byte.
SHA-256: `c3f9a12ff1b05857477f405c2cae0aba633434b9af69bfbb91ebd238a7a7d2ab`.
Seluruh gate lulus sebelum commit: format, analyze, 126 tes Flutter, 38 rules test,
build APK, capture before/after, dan `git diff --check`. Diff commit dibatasi pada
tiga source UI, dua file test, laporan ini dan enam screenshot.

- Hard Gate PASS: kontrol dan data aktual, tidak ada field atau status palsu; guard
  repository/rules dan route role tetap digunakan; loading/error/retry/empty ada.
- Purpose Gate PASS: kartu memisahkan entitas, badge menjelaskan state, ikon kendaraan,
  teknisi dan sparepart mengikuti isi; section tambahan menjaga operasi existing.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1; keluarga ilustrasi biru, aksen amber
  pada aset, border tipis dan whitespace berasal dari referensi bengkel.
- Craftsmanship PASS: before/after ditinjau; posisi badge, kepadatan kartu, urutan aksi
  dan header teks besar diperbaiki. Kontrol Material menyediakan focus/keyboard,
  tooltip dan tap target; informasi status tidak mengandalkan warna saja.
  Kontras tema existing: navy/background sekitar 10,99:1, putih/Royal Blue 5,17:1,
  muted/putih 7,58:1; border kontrol/putih 4,76:1. Label semantic status memakai
  warna gelap di atas tint, bukan teks amber terang di atas putih.

Tidak mengklaim 100% identik. Gap model, workflow, font, aset dan perangkat di atas
tetap berlaku.

Capture after:

```text
flutter test test/admin_service_refinement_test.dart --plain-name "admin refinement captures technicians orders and detail" --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/screenshots/admin-refinement-04/after
```
