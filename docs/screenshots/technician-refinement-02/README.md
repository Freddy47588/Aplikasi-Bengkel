# Teknisi — Checklist dan Sparepart

Audit awal: `5e8557428bbb58db8e44a182b875b06bfc61a9d1` pada `main`.
Source, working tree, model checklist, repository inventori, transisi SO dan rules
dibaca sebelum perubahan. Perubahan lokal generated plugin desktop sudah ada
sebelumnya, dicadangkan di build dan tidak disertakan dalam commit ini.

## Mapping dan bukti render

| Referensi | Implementasi | Before | After |
| --- | --- | --- | --- |
| Checklist Pekerjaan | `WorkEditor` pada tugas milik teknisi | [Before](before/fixture-refinement-checklist.png) | [After](after/fixture-refinement-checklist.png) |
| Permintaan Sparepart | `PartRequestScreen` dari tugas yang memenuhi syarat | [Before](before/fixture-refinement-part-request.png) | [After](after/fixture-refinement-part-request.png) |
| Penyelesaian Servis | `ServiceCompletionScreen`, dibuka melalui aksi pengajuan existing | [Before: titik masuk pada detail](before/fixture-refinement-completion.png) | [After: ringkasan pengajuan](after/fixture-refinement-completion.png) |

Render widget Flutter pada 390 × 844dp, DPR 2, font Roboto dan Material Icons asli.
Ini bukti render fixture otomatis, bukan foto perangkat atau produksi. Semua nilai
uji disimpan dalam FakeFirestore dan dibaca melalui provider/repository aplikasi;
tidak ada data contoh yang ditambahkan ke source production. Sebelum perubahan
belum ada layar ringkasan penyelesaian terpisah, sehingga baseline ketiga merupakan
detail tugas sebagai titik masuk pengajuan, bukan layar yang sama.

## Perbandingan dengan area di dalam ponsel mockup

Header putih terpusat, ilustrasi biru, deskripsi, kartu kendaraan, border biru muda,
checkbox, CTA Royal Blue dan wave bawah mengikuti komposisi referensi. Bingkai
ponsel, Dynamic Island, jam, poster dan panel keterangan tidak disalin.

Checklist sekarang menampilkan kartu pemeriksaan dengan judul tebal dan deskripsi.
Diagnosis, tindakan dan catatan tetap dapat diedit melalui section yang bisa dibuka.
Pada 390dp, tiga pemeriksaan aktual dan CTA simpan terlihat bersama ilustrasi.
Permintaan memakai kartu SKU dan stepper dengan input numerik tetap tersedia.
Ringkasan menampilkan diagnosis, tindakan, pemakaian aktual dan progres sebelum
konfirmasi. Setelah render pertama, hero penyelesaian diperkecil menjadi 112dp
dan badge terpisah yang mengulang timeline dihapus; timeline kini terlihat utuh
di atas CTA pada fixture 390dp. Konten panjang tetap dapat digulir.

Ukuran utama: padding horizontal 16dp, hero checklist/toolbox 128dp, kartu radius
14–16dp, ikon 26–30dp, CTA minimal sesuai tema existing. Palet mengikuti Steel Navy
`#1E3A5F`, Royal Blue `#2563EB`, Amber `#F59E0B`, background `#F8FAFC`. Warna teks
sekunder dan semantic memakai kontras tema existing. Aset `checklist`, `spareparts`
dan `completion` existing dipakai kembali, tanpa generasi screenshot sebagai UI.

## Penyimpangan yang sengaja dipertahankan

- Model hanya mendukung `vehicleChecked`, `safetyChecked`, `workChecked`; tidak
  ditambah pemeriksaan oli, rem, lampu atau rantai/ban palsu dari mockup.
- Teknisi tidak memiliki akses katalog master sparepart menurut rules. Form tetap
  satu SKU per permintaan, bukan daftar nama produk yang tidak dapat dibaca.
  Jumlah 1–1.000.000 mengikuti batas repository existing; stok tidak dikurangi
  saat mengajukan. Persetujuan admin tetap memeriksa dan membukukan stok.
- Alasan permintaan tetap wajib dengan batas 500 karakter. Field opsional baru
  tidak ditambahkan karena kontrak backend tidak mendukungnya.
- Timeline mengikuti status aktual. Pengajuan mengubah ke `awaitingApproval`,
  tidak langsung `completed`; kelengkapan checklist/diagnosis/tindakan dan revisi
  tetap divalidasi repository. Harga dan persetujuan akhir tetap milik admin.
- Pemakaian dan reversal ditampilkan terpisah dengan snapshot SKU/nama/unit/jumlah
  aktual. Pagination existing dipakai; tidak menghitung total bersih yang menutupi
  reversal. Histori, approval/rejection dan reversal pada halaman sparepart existing
  tetap tersedia.
- Tipografi Material/Roboto dan ilustrasi existing mendekati gaya referensi, namun
  bukan aset atau font identik. Wave lebih tipis agar tidak menutup konten.
- Ilustrasi disembunyikan pada text scaling di atas 1,3× agar form tetap mudah
  digunakan. Pada teks besar, timeline memakai susunan responsif existing.

## Validasi

Tes baru memeriksa batas bawah/atas stepper, jumlah tidak valid, alasan wajib,
permintaan pending tanpa perubahan stok, konflik revisi pada dialog pengajuan,
dan pengajuan hanya sampai menunggu persetujuan. Regresi existing mencakup
mulai/pause/resume, penyimpanan catatan/checklist, approval admin, histori,
approval/rejection sparepart, idempotensi, reversal dan stok.

Ketiga form diuji pada 320/360/390/430dp dengan text scaling 1/1,3/2×, termasuk
section catatan terbuka dan gulir ke konten bawah. Tidak ada Infinix/perangkat ADB
terhubung; uji perangkat fisik dan build iOS belum dilakukan pada Windows.

Perintah capture:

```text
flutter test test/technician_forms_refinement_test.dart --plain-name "technician forms refinement captures checklist request and completion entry" --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/screenshots/technician-refinement-02/after
```

Quality gate dan log lokal berada di `build/technician-forms-*.log`:

| Gate | Hasil |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | PASS, 87 file, 0 perubahan |
| `flutter analyze` | PASS, no issues found |
| `flutter test --reporter expanded` | PASS, 120 tes |
| Capture ketiga layar | PASS, font asli, 390dp, before/after disertakan |
| Firebase Emulator/rules | PASS, 38 tes, 0 gagal |
| `flutter build apk --debug` | PASS, native exit code 0; verifikasi ulang 63,9 detik |
| `git diff --check` | PASS |

Firebase rules dijalankan pada proyek demo terisolasi dengan Firestore 18080/Auth
19099, tanpa deploy atau reset produksi. Build pertama selesai dalam 746,5 detik,
tetapi wrapper PowerShell mengembalikan error karena warning stderr Java; native
exit code diperiksa ulang melalui redirection CMD dan terkonfirmasi 0 pada
`technician-forms-build-confirmed.log`. Plugin `firebase_auth` dan
`firebase_core` masih memberi warning kompatibilitas KGP untuk Flutter mendatang;
dependency/build configuration tidak diubah dalam refinement UI ini.

APK: `build/app/outputs/flutter-apk/app-debug.apk` (216.300.547 byte).
SHA-256 build terverifikasi: `dee6d3fdd459f29dd7264fba59cdd8cb847bcc018562bfcc303f5c48c1ed25eb`.

## Delivery gate antislop

- Hard Gate PASS: data dinamis dan callback nyata; tidak ada katalog, checklist,
  status selesai, atau field backend palsu. Form dan ringkasan memeriksa tugas
  milik sendiri; repository/rules tetap menjadi batas otorisasi.
- Purpose Gate PASS: ilustrasi dan ikon menjelaskan pemeriksaan, sparepart dan
  pengajuan hasil pekerjaan; status dan teks tidak mengandalkan warna saja.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1, sesuai mockup; whitespace,
  border tipis dan aset 2.5D existing, tanpa animasi dekoratif tambahan.
- Craftsmanship PASS: before/after ditinjau, gap hero/timeline diperbaiki, data
  panjang dapat digulir, teks besar diuji dan semua tindakan lama tetap tersedia.
  Kontras tema: navy/background sekitar 10,99:1, putih/blue 5,17:1, muted/putih
  7,58:1; checkbox unchecked memiliki outline, kontrol angka memiliki tooltip.

Tidak ada klaim 100% identik; perbedaan model, workflow, aset dan pengujian
perangkat di atas tetap berlaku.
