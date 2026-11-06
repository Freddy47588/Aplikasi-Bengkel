# Pelanggan — Beranda dan Kendaraan

Audit awal: `7e058fe402b7b605917a030d987c995ff4f4d96b`, branch `main`.
Fetch berhasil dan HEAD sesuai origin/main saat audit. Tujuh generated plugin
desktop sudah berubah sebelumnya; dicadangkan di `build/customer-03-local-backup`
dan tidak dimasukkan ke commit ini. Tidak ada migrasi, perubahan rules, repository,
model, transaksi, autentikasi atau pekerjaan notifikasi.

## Pemetaan TA dan source

| Kebutuhan | Cakupan refinement |
| --- | --- |
| F-02 / UC-02 | Daftar, tambah, edit dan arsip kendaraan milik pelanggan; hanya field yang didukung |
| F-03 / UC-03 | Buat Booking, Booking Saya dan booking aktif menggunakan route/provider existing |
| F-07 / UC-04, UC-12 | Status SO aktual, akses detail progres, histori terbaru dan Riwayat Servis |

BAB III bagian 3.12.2 pada laporan TA A5 yang sebelumnya ditemukan dalam lampiran
ChatGPT menyatakan UC-02: pelanggan aktif mengisi nomor polisi, merek, tipe, tahun,
kemudian validasi dan simpan dengan identitas terhubung pemilik. Bagian 3.12.3
menjelaskan booking, dan 3.12.4/3.12.12 menjelaskan status serta riwayat.
Dokumen diperlakukan sebagai acuan kebutuhan; tidak diubah pada pekerjaan ini.

Source yang diubah: `customer_dashboard_screen.dart`, `vehicles_screen.dart`,
komponen ilustrasi khusus pelanggan `customer_vehicle_art.dart`, serta delegasi
cabang pelanggan pada `live_dashboard.dart`. Cabang admin dan teknisi tetap memakai
layar existing. Tidak ada Phase 08 otomatis.

## Hasil UI

Beranda memakai sapaan dan email sesi aktual, hero motor biru/mobil putih,
kartu Ringkasan Servis yang sedikit bertumpuk dengan hero, tiga akses cepat
(Buat Booking, Kendaraan Saya, Riwayat Servis), serta servis/booking aktif.
Statistik memakai SO aktif dan SO selesai dari maksimal 20 SO terbaru pelanggan;
tidak diklaim sebagai total sepanjang waktu. Cuplikan aktif dibatasi 3 SO dan
3 booking dari masing-masing 20/100 data terbaru dengan caption cakupan.
Tidak ada estimasi selesai atau statistik harian yang dibuat-buat.

Menu Booking Saya, Progres Servis dan Invoice & Pembayaran tetap ada pada Menu
lainnya. Ringkasan dua metrik booking, kendaraan terdaftar, booking terbaru dan
riwayat terbaru tetap dapat dibuka. Pelacakan lengkap tersedia melalui detail SO
existing. Informasi cache/offline pada histori tetap ditampilkan. Logout dan
navigasi bawah dipertahankan. Source HEAD belum menyediakan fitur notifikasi
yang dapat ditautkan, sehingga tidak dibuat lonceng tanpa aksi.

Kendaraan Saya memakai AppBar putih terpusat, ilustrasi baru, heading dan deskripsi,
kartu border biru muda dengan plat tebal, nama, status aktif dan chevron edit.
Hapus/arsip tetap mempunyai tombol dan konfirmasi existing. CTA tambah dipasang
di atas navigasi bawah agar tidak menutupi daftar.

Form tetap memakai dialog scrollable existing dengan ilustrasi biru, input nama
dan plat, ikon konsisten serta tombol Simpan. Validasi nama, normalisasi plat,
loading/error dan operasi save tetap dipakai. Label tombol existing dipertahankan.
Tidak ada pilihan jenis, tahun atau catatan yang seolah-olah tersimpan.

## Aset generated

Pengguna secara eksplisit meminta regenerasi ilustrasi sesuai mockup. Dua aset
individual dibuat menggunakan image-generation tool, dengan gambar poster hanya
sebagai referensi kendaraan, komposisi dan gaya. Aset tidak berisi UI, teks, data,
logo, watermark atau bingkai ponsel.

| Aset | Penggunaan | Ukuran setelah optimasi |
| --- | --- | --- |
| [Motor biru dan mobil putih](../../../assets/illustrations/customer-vehicles-reference.png) | Hero beranda dan daftar kendaraan | 1024 × 394px, 428.327 byte, alpha transparan |
| [Motor dan mobil biru](../../../assets/illustrations/customer-vehicle-form-reference.png) | Form tambah/edit | 1024 × 427px, 310.334 byte, alpha transparan |

Output asli sekitar 1,38MB dan 0,95MB dipertahankan di lokasi generated-images.
Salinan proyek diperkecil dengan Sharp menjadi lebar 1024px, PNG terkompresi,
tanpa menghilangkan alpha. Bitmap lama tidak ditimpa sehingga ilustrasi modul lain
tidak ikut berubah. Folder ilustrasi sudah terdaftar di pubspec; cache decode
dibatasi ukuran viewport dan resolusi aset. Preview hasil generation ditampilkan
langsung dalam percakapan.

## Gap UC-02, mockup dan implementasi

| Aspek | Implementasi aktual / keputusan |
| --- | --- |
| Nomor polisi | `plate`, dinormalisasi repository; validasi existing dipertahankan |
| Merek/model | Satu string `name`, 1–80 karakter; belum terpisah secara terstruktur |
| Tipe dan tahun UC-02 | Belum ada pada model/repository/rules; tidak ditambahkan diam-diam |
| Motor/Mobil dan catatan mockup | Tidak didukung schema saat ini; tidak ditampilkan sebagai field semu |
| Pemilik | `ownerId`, tidak dapat dialihkan melalui edit existing |
| Status | Query hanya memuat kendaraan `active == true`, maksimal 50; badge Aktif mengikuti hasil query tersebut |
| Hapus | Repository mengarsipkan dengan `active: false`, bukan menghapus dokumen atau riwayat |
| Layar form | Dialog existing dipertahankan, bukan halaman penuh seperti poster |

Rules kendaraan memakai allowlist `ownerId`, `name`, `plate`, `active`,
`createdAt`, `updatedAt`. Field tambahan akan ditolak; model Vehicle hanya
menyediakan id, name, plate dan ownerId. Karena itu kesesuaian penuh UC-02 belum
dapat diklaim hanya dari refinement visual ini.

### Rekomendasi pekerjaan schema terpisah

Jika semua field UC-02 wajib dipenuhi, sepakati terlebih dahulu arti “tipe”:
kategori motor/mobil atau tipe/model kendaraan. Rancang field merek, tipe dan tahun
yang terstruktur; catatan opsional hanya bila disetujui sebagai kebutuhan.
Tentukan validasi domain, batas input dan kompatibilitas kendaraan lama.
Jangan mengarang tahun/kategori untuk backfill data yang tidak diketahui.

Perubahan berikutnya harus mencakup model/draft, repository, allowlist dan validasi
rules, migrasi eksplisit/backward compatibility, snapshot booking yang terkait,
serta tes ownership, input tidak valid, edit/arsip dan regresi booking/histori.
Pengujian dilakukan di emulator demo terlebih dahulu. Migrasi/deploy produksi
memerlukan persetujuan terpisah. Tidak ada bagian rekomendasi ini yang dijalankan
pada commit UI ini.

## Bukti visual dan batas verifikasi

Sesuai instruksi terakhir pengguna untuk tidak melakukan pengujian tambahan,
tidak dijalankan pub get, analyze, test, build APK, emulator/rules test, atau uji
perangkat pada refinement ini. Tidak ada klaim PASS berdasarkan run sebelumnya.
Formatter hanya dipakai untuk merapikan file UI yang ditulis; diff direview.

Capture Flutter before/after baru juga **NOT RUN** karena harness capture yang
tersedia memakai `flutter test`; tidak dijalankan setelah pengguna meniadakan
pengujian. Referensi historis berikut tetap tersedia, tetapi bukan capture HEAD
baru dan tidak dipresentasikan sebagai bukti pixel accuracy perubahan ini:

- [Beranda lama](../visual-fidelity/after/fixture-alignment-customer-home.png)
- [Daftar kendaraan lama](../visual-fidelity/after/fixture-alignment-customer-vehicles.png)

Aset generated sudah ditinjau secara visual. Implementasi memakai layout gulir,
Wrap dan kolom pada text scaling besar, serta menyembunyikan hero dekoratif di
atas 1,3×. Responsivitas 320/360/390/430dp, text scaling, keyboard, navigasi dan
transaksi pada source baru **belum diverifikasi melalui eksekusi**. Infinix dan
iOS **NOT RUN**. QA Gate Phase 07/UAT tetap mengikuti laporan existing.

Perbedaan yang tersisa: bentuk kendaraan generated dan font tidak identik dengan
poster, ikon kartu bersifat umum karena tidak ada tipe kendaraan, status nonaktif
tidak muncul karena query existing hanya aktif, form tetap dialog, serta navigasi
dan menu existing memerlukan ruang tambahan. Tidak diklaim 100% identik.

## Review antislop

- Data, status dan tindakan memakai provider/route nyata; tidak ada field backend
  palsu atau angka contoh production.
- Kartu, badge, hero dan wave mengikuti fungsi dan referensi; tidak mengganti UI
  dinamis dengan gambar statis.
- ENERGY 2 / RHYTHM 2 / MOTION 1, palet navy/blue/amber existing dan aset terpisah.
- Review source dan aset selesai; delivery gate yang memerlukan render/tes tetap
  NOT RUN sesuai instruksi pengguna, bukan PASS yang diasumsikan.
