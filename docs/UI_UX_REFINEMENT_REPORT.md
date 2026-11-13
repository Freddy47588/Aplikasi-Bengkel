# Refinement interaksi BengkelKu, 12-13 November 2026

Anti Slop mode `during`, dipilih pengguna untuk sesi ini. Arah: aplikasi
operasional bagi pelanggan, kasir/admin dan teknisi; ENERGY 1 / RHYTHM 1 /
MOTION 1. Tidak ada redesign, aset, navigasi baru atau theme toggle.

Perubahan UI terbatas pada kesiapan tombol Konfirmasi Booking dan feedback
katalog berubah. Satu dialog review untuk satu aksi, input keluhan tetap ada
saat pilihan harus diperbaiki, cancel membuka form kembali. Dropdown layanan
dan kendaraan existing tetap menggunakan opsi repository, label, native focus,
height adaptif dan validasi. Dialog memakai snapshot untuk review stabil.

## Alasan desain

- Steel Navy/Royal Blue, Amber dan off-white mengikuti brief serta tema existing.
- Susunan kendaraan/layanan, jadwal, keluhan, review mengikuti urutan keputusan pelanggan.
- Tipografi dan spacing existing dipertahankan supaya perbaikan tidak mengubah ritme aplikasi.
- Tombol disabled saat katalog belum siap mencegah tindakan yang belum bisa diproses.
- Pesan katalog berubah menyebut tindakan berikutnya dan tidak menghapus keluhan.
- Kartu, ikon bengkel dan ilustrasi existing tidak ditambah; tidak ada dekorasi baru.
- Tidak menambah animasi, sehingga status readiness dan dialog tetap menjadi fokus.

## Bukti interaksi

| Kontrol | Aksi yang dijalankan | Expected / actual |
| --- | --- | --- |
| Kendaraan | Buka, pilih Honda fixture | Pilihan tersimpan pada form |
| Jenis layanan | Buka, pilih; kosongkan katalog; isi Servis Rem | Pilihan baru dapat dibuka, pilihan hilang tidak valid |
| Retry katalog | Error stream, tap Coba lagi | Provider dimuat ulang, opsi Ganti Oli kembali |
| Tanggal/jam/keluhan | Date picker, 09:00, input keluhan | Form dapat direview; tes existing memeriksa submit akhir |
| Konfirmasi Booking | Panggil dua kali sebelum frame berikut | Tepat satu dialog |
| Kembali | Tutup review | Tidak ada write; tombol kembali tersedia |
| Katalog berubah sebelum frame | Hapus layanan setelah isi form lalu submit | Feedback, tidak crash, tidak menulis booking |
| Kirim Booking | Suite booking_review_layout/mobile_foundation | Navigasi ke detail; state booking diperiksa |

Screenshot fixture berpasangan ada pada `evidence/full-audit-20261112/before/`
dan `after/`: katalog kosong bagian atas dan tombol submit di bawah. Before
memakai source booking dari base HEAD; after memakai perbaikan audit, viewport
390x740, skala 100%, font Roboto SDK. Ini raster Flutter dengan fixture test,
bukan screenshot Infinix, bukan production dan bukan bukti UAT.

Referensi 10 mockup asli tidak ditemukan sebagai gambar pada lampiran sesi.
Artefak UI/ilustrasi existing dan laporan visual historis tersedia, tetapi audit
ini tidak mengklaim perbandingan langsung dengan semua mockup asli.

## Gate Anti Slop pada perubahan sesi

Gate dibatasi kontrol booking yang diubah, bukan sertifikasi semua layar.
Lihat log dan hasil akhir di REGRESSION_RESULTS; gate aplikasi/perangkat masih
mengikuti QA_GATE yang BLOCKED.

- R-02/R-15/R-16/R-36/R-38 PASS: pesan baru menyebut perubahan katalog/tindakan nyata; tidak ada em dash, slogan, statistik atau klaim rekaan.
- R-17/R-18 PASS: diff tidak menambah statistik, testimoni atau identitas pengguna; isi screenshot ditandai fixture.
- R-24/R-26/R-27 PASS: route tetap, dropdown/retry/review/cancel/submit diuji; katalog kosong/loading/error tidak dianggap siap.
- R-25 PASS pada perubahan: teks feedback memakai danger #B91C1C pada #F8FAFC (6,18:1); CTA putih pada #2563EB (5,17:1), teks pendukung #475569 pada #F8FAFC (7,24:1), dihitung dari luminans sRGB. Tombol disabled memang nonaktif dan tidak memakai ambang teks aktif.
- R-03/R-32/R-39 PASS pada kontrol yang diubah: komponen native Material existing dipertahankan, tidak membatasi skala teks atau menghapus label/focus; tes keyboard existing tetap dijalankan.
- R-23/R-33/R-34/R-40 PASS pada diff: tidak membuat aset/tema, tidak memodifikasi UI lewat script pengganti string, tidak menambah media atau klaim performa. Restorasi sementara source baseline hanya untuk capture sebelum/sesudah.
- R-28 PASS: tidak ada FAQ pada kontrol booking atau dalam perubahan ini.
- R-37 PASS: arah operasional BengkelKu dan dial 1/1/1 dinyatakan sebelum perubahan, sesuai brief empat warna dan larangan redesign.
- R-01/R-04/R-06..R-14/R-19/R-22/R-29/R-31 PASS pada diff: tidak menambah teknik dekorasi; alasan mempertahankan palet/layout/typography/spacing dicatat di atas.
- Liveliness PASS pada lingkup form: dial 1/1/1, fokus review booking, kelompok field dan jarak existing, identitas bengkel existing; tidak menambah template landing page.
- C-1..C-5/R-05/R-11/R-20/R-21/R-30 PASS pada diff: alasan spesifik, aksi nyata, konten domain existing, error/retry, tanpa klaim fiktif atau kloning desain baru.
- R-35 PASS pada lingkup perubahan: APK debug dibangun, 142 tes Flutter lulus, interaksi tabel di atas dijalankan, empat PNG before/after diperiksa; tidak ada teks keluar container pada capture.

Kontras tema tidak diubah. Tidak mengklaim pengukuran kontras ulang seluruh
gambar/teks, audit screen reader native atau click-through semua kontrol native.
