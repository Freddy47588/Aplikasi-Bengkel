# UI Refinement 03: dashboard dan tugas teknisi

Tanggal: 6 November 2026. Audit awal: `main`, HEAD
`d638154ed44749ea666968ae7875734482eda939`, sama dengan `origin/main` setelah fetch.
Source aktual yang dibaca: `live_dashboard.dart`, wrapper dashboard/jobs teknisi,
`service_orders_screen.dart`, timeline/model, repository SO/history/inventory,
router, form permintaan sparepart, dan Firestore rules.

Perubahan splash Android dan registrasi plugin desktop pada working tree
dipertahankan. `docs/SPLASH_REFERENCE_REPORT.md` juga sedang berubah di luar
pekerjaan ini dan tidak disertakan dalam commit refinement. Tidak memulai Phase 08.

## Screenshot before/after

Render **widget Flutter aktual melalui router aplikasi**, bukan screenshot UI
statis untuk menggantikan komponen. Viewport 390 × 844dp, DPR 2, raster
780 × 1688px, text scale 100%, font Roboto/Material Icons aktual dari SDK.
Database fake hanya berada di test harness. Before diambil sebelum perubahan
source production; before dan after memakai fixture yang sama, dengan tanggal
tetap dan satu tugas teknisi lain untuk menguji scope. Nama, nomor SO, kendaraan,
jumlah, jadwal, dan status production tetap berasal dari provider/repository.

| Layar | Before | After |
| --- | --- | --- |
| Dashboard Teknisi | [Before](before/fixture-refinement-technician-dashboard.png) | [After](after/fixture-refinement-technician-dashboard.png) |
| Daftar Tugas | [Before](before/fixture-refinement-technician-tasks.png) | [After](after/fixture-refinement-technician-tasks.png) |
| Detail Tugas | [Before](before/fixture-refinement-technician-detail.png) | [After](after/fixture-refinement-technician-detail.png) |

Yang dijadikan referensi hanya antarmuka di dalam ponsel. Bingkai, Dynamic
Island, jam 9:41, logo poster, panel keterangan, dan label luar tidak dibuat.

## Mapping fungsi dan keputusan visual

### Dashboard

- `TechnicianDashboardScreen` tetap memanggil `LiveDashboard`; hanya cabang
  `technician` yang diarahkan ke `TechnicianOverview`. Dashboard admin dan
  pelanggan tetap memakai susunan existing.
- Salam Selamat Datang dan identitas dari bagian nama email AuthSession mengganti
  hero panel besar. Deskripsi dan kombinasi aset technician + garage existing
  menampilkan teknisi, bengkel, serta mobil. Tidak ada identitas pribadi dummy.
- Ringkasan mengambil `ordersPageProvider(null)` existing: query SO milik UID
  teknisi, diurutkan createdAt/id, limit 20. Total Tugas mencakup seluruh status
  pada halaman pertama; Sedang Dikerjakan hanya `inProgress`; Selesai hanya
  `completed`. Caption menyatakan **maksimal 20 tugas terbaru, bukan ringkasan
  harian**. Tidak menghitung seluruh bengkel atau mengarang hitungan hari ini.
- Pekerjaan Aktif menampilkan maksimal tiga SO nonterminal dari hasil tersebut.
  Kartu memperlihatkan ID SO aktual, kendaraan/plat, layanan, dan status.
- Tugas Saya menuju `/technician/jobs`; Riwayat Pekerjaan menuju
  `/technician/history`. Permintaan Sparepart membuka pilihan tugas milik sendiri
  yang `inProgress`/`paused`, lalu form `PartRequestScreen` existing. Jika belum
  ada tugas yang memenuhi syarat, tersedia penjelasan dan akses daftar lengkap.
  Daftar pilihan dibatasi hasil 20 tugas terbaru dan menjelaskan batas itu.
  Menu permintaan dinonaktifkan saat data belum tersedia; retry ada pada error.
- Progres Servis dan riwayat servis terbaru existing tetap tersedia di bawah
  menu cepat. Logout dan navigasi bawah juga dipertahankan.

### Daftar tugas

- Kedua route `/technician/jobs` dan `/technician/orders` tetap memakai
  `ServiceOrdersScreen`, dengan tampilan khusus teknisi. Provider, repository,
  cursor, pemuatan realtime, loading, error/retry, dan pagination tetap sama.
- AppBar putih, judul terpusat, ilustrasi/deskripsi, search dan tombol filter
  terpisah, serta kartu putih berborder biru tipis mengikuti komposisi referensi.
- Backend existing belum mempunyai query pencarian/filter status untuk SO.
  Search ID/plat/nama kendaraan/layanan dan filter status dilakukan secara lokal
  pada **halaman aktif**, dengan caption scope yang selalu terlihat. Pagination
  tetap dapat dipakai walau hasil filter kosong, dan filter dipertahankan saat
  berpindah halaman. Tidak menyamarkan pencarian halaman sebagai pencarian global.
- `assigned` ditampilkan sebagai Menunggu (amber), `inProgress` sebagai Diproses
  (biru), `completed` sebagai Selesai (hijau). Antrean, Dijeda, Menunggu Persetujuan
  Admin, dan Dibatalkan tetap memiliki label tersendiri; status domain tidak diubah.

### Detail tugas

- Khusus teknisi: header ID SO/status, Informasi Kendaraan, Jenis Servis,
  Jadwal Pengerjaan dari scheduledAt (WIB), Catatan Keluhan, dan timeline tiga
  tahap mengganti susunan detail panjang. Nilai jadwal kosong diberi label
  Belum tersedia, bukan tanggal contoh.
- Tiga tahap timeline adalah ringkasan presentasi atas status existing. Dijeda
  dan Menunggu Persetujuan Admin tetap diberi keterangan aktual; Dibatalkan
  menghentikan proses dengan penanda merah. Selesai hanya ditandai tercapai jika
  status benar-benar `completed`. Penanda dan label disejajarkan per kolom.
- Tombol Mulai/Lanjut memakai biru; Jeda dan Ajukan Selesai outlined. Tombol hanya
  dihasilkan dari `canTransitionTo(..., admin: false)`. Dialog konfirmasi,
  updateWork/revision, validasi checklist/diagnosis/tindakan, dan feedback error
  tetap digunakan. Pengajuan selesai tetap membutuhkan persetujuan admin.
- Checklist dan catatan kerja, sparepart/permintaan, serta akses riwayat untuk
  tugas selesai tetap tersedia. Checklist tersimpan, diagnosis/tindakan/catatan,
  identitas penugasan, waktu pembaruan, dan biaya jasa tetap dapat dibaca melalui
  section yang bisa dibuka. Aksi tidak digantikan placeholder.
- UI menolak detail teknisi lain, melengkapi aturan akses backend existing.
  Rules dan repository tidak dilonggarkan; tampilan admin/pelanggan tetap sama.

## Perbandingan dan gap yang tersisa

| Aspek | Hasil perbandingan |
| --- | --- |
| Komposisi dashboard | Panel hero lama diganti salam/deskripsi, ilustrasi lebar, ringkasan tiga nilai, pekerjaan aktif, dan tiga menu cepat. Ringkasan dan menu cepat kini terlihat lebih awal. |
| Proporsi dan spacing | Padding horizontal 16dp, jarak antar kartu tugas 8dp, radius kartu 14/16dp. Ilustrasi dashboard dikurangi dari 128 ke 112dp setelah render pertama agar menu lebih mudah terlihat; hero daftar 128dp. |
| Daftar | Nomor SO dan badge menjadi baris utama; data kendaraan/layanan berada di bawah; chevron tetap membuka detail. Search/filter menambah ruang vertikal dibanding baseline yang belum mempunyai kedua kontrol tersebut. |
| Detail dan timeline | Informasi utama dan aksi berada sebelum data pemeriksaan tambahan. Timeline vertikal lima tahap existing untuk role lain tidak diubah; teknisi memakai tiga kolom pada skala normal dan susunan vertikal pada teks di atas 130% agar terbaca. |
| Warna dan tipografi | Steel Navy, Royal Blue, off-white, status semantik, dan aksen amber aset existing dipakai. Roboto existing dipertahankan; bentuk huruf tidak identik dengan lettering mockup. |
| Ilustrasi | Aset technician, garage, dan checklist sudah transparan, relevan, dan bergaya biru/putih. Komposisi dashboard memakai dua aset individual existing. Ilustrasi daftar masih clipboard + mobil, berbeda dari clipboard + wrench pada mockup; tidak membuat aset baru. |

Penyimpangan karena fungsi/data:

- Tidak ada fitur/provider/route notifikasi pada source aktual yang diaudit.
  Lonceng tidak ditambahkan sebagai tombol palsu; logout existing tetap tersedia.
- Schema SO tidak menyimpan snapshot nama/telepon pelanggan, dan rules teknisi
  tidak memberi akses profil pelanggan. Section kontak pelanggan tidak dibuat,
  dan tidak ada query tambahan untuk mengambil informasi pribadi tersebut.
- Kartu Ringkasan Pekerjaan tidak memakai label Hari Ini, karena query actual
  bukan query harian. Nilai fixture 4/1/2 berbeda dari angka poster.
- Pada SO Diproses, aksi yang benar adalah Jeda/Ajukan Selesai, bukan Mulai
  seperti kombinasi contoh mockup. Assigned menampilkan Mulai, Paused menampilkan
  Lanjutkan, dan awaitingApproval menunggu keputusan admin tanpa tombol persetujuan.
- Navigasi bawah, informasi tambahan, Progres Servis, dan riwayat terbaru
  dipertahankan sehingga tinggi/isi halaman berbeda dari mockup. Wave existing
  dibatasi 32dp pada ruang tersendiri, bukan overlay, dan hilang ketika keyboard
  terbuka. Konten tetap dapat digulir sampai aksi dan pagination terakhir.

Tidak ada klaim 100% identik. Bukti ini adalah render widget dengan data uji,
bukan screenshot production/perangkat fisik. Build iOS/perangkat fisik belum
diuji pada host Windows; widget dan aset tetap memakai API lintas platform.

## Validasi dan Delivery Gate

- Format: `dart format --output=none --set-exit-if-changed lib test`, 84 file,
  nol perubahan.
- Analyze: `flutter analyze`, no issues found.
- Flutter: `flutter test`, **116 lulus, 0 gagal**.
- APK: `flutter build apk --debug`, berhasil; assembleDebug 342,3 detik.
  SHA-256: `571519cd7d5b87d98a7a29efa78385aa4d686ffc6aa120e306a0d874bc51c074`.
  Build memakai working tree aktual, termasuk perubahan splash lokal yang tidak
  ikut commit ini. Warning KGP plugin Firebase existing masih muncul; dependency
  tidak diubah dalam refinement visual.
- Rules: seluruh `test_rules/*.test.cjs`, **38 lulus, 0 gagal**, termasuk
  isolasi teknisi, transisi status, histori immutable, dan integrasi Phase 07.
  Emulator lokal terpisah memakai demo-bengkelku, Firestore 18080, Auth 19099,
  hub 14400, logging 14500. Instance existing pada port default tidak di-reset.
  Tidak ada Firebase production deploy atau perubahan data asli.
- Test baru mencakup 36 kombinasi layar/lebar/skala (320/360/390/430dp dan
  100/130/200%), tujuh status, penolakan akses tugas teknisi lain, ringkasan
  terbatas 20, pencarian lintas halaman yang jelas scope-nya, filter status,
  pagination, mulai/jeda/lanjut, penolakan pengajuan tidak lengkap, simpan
  checklist/catatan, pengajuan/persetujuan, riwayat, serta request sparepart pending.
- Hard Gate PASS: data dan kontrol aktual; loading/error/retry/empty state;
  native Material focus/keyboard dan label; tidak ada dummy production,
  kontak pelanggan palsu, lonceng kosong, atau statistik harian tanpa query.
  Kontras WCAG terhitung: navy/background 10,99:1, putih/Royal Blue 5,17:1,
  muted/putih 7,58:1, status amber 5,73:1, hijau 5,95:1, biru 5,57:1 pada
  tint status 12% di atas putih; border kontrol/putih 4,76:1.
- Purpose Gate PASS: border memisahkan SO, badge menjelaskan status, ikon kendaraan
  dan wrench menjelaskan isi, biru menandai aksi awal; tanpa shadow/glow baru.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1 dari referensi bengkel biru;
  ilustrasi sebagai fokus, urutan ringkasan/pekerjaan/menu, amber terbatas pada
  status dan aset, tanpa animasi dekoratif baru.
- Craftsmanship PASS: before/after ditinjau, hero diperkecil dan timeline dirapikan;
  akses dan transaksi dipertahankan, teks besar reflow, navigasi tambahan disimpan.

Regenerasi after:

```powershell
flutter test test/technician_refinement_test.dart --plain-name "technician refinement captures actual dashboard list and task detail" --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/screenshots/technician-refinement-03/after
```

Log lokal: `build/technician-refinement-*.log` (diabaikan Git).
Semua quality gate lulus sebelum commit. Commit dibatasi pada empat source UI,
empat file test terkait, laporan ini, dan enam screenshot before/after.
