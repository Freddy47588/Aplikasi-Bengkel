# Anti Slop delivery gate

Gate tambahan untuk splash biru 5 November 2026 berada pada
[laporan splash](SPLASH_REFERENCE_REPORT.md). Alasan gradient dan wave pada
splash mengikuti permintaan referensi terbaru; penilaian di bawah mencatat
audit UI sebelum perubahan splash tersebut.

Mode during dari pilihan sesi. Scope: perubahan UI Flutter pada audit visual
fidelity, bukan sertifikasi seluruh platform. Bukti: 10 papan pengguna,
37 render fixture, 99 tes, analyze dan build APK debug. Native UAT/iOS serta
print/share belum dijalankan dan tetap dicatat NOT RUN pada laporan utama.

## Hard gate

| Aturan | Status | Bukti |
| --- | --- | --- |
| R-02 | PASS | Copy baru tidak memakai em dash |
| R-03 | PASS | Tes 320/360/390/430/800dp dan 100/130/200% tanpa overflow |
| R-17 | PASS | Metrik berasal dari provider dengan limit query tertulis |
| R-18 | PASS | Tidak ada testimonial atau avatar pelanggan rekaan |
| R-23 | PASS | Generasi/perbaikan aset diminta eksplisit pada master prompt |
| R-24 | PASS | Semua shortcut dashboard ditap dan route tujuan diperiksa pada tes |
| R-25 | PASS | Kontras token dihitung: slate/off-white 7.24, putih/blue 5.17, status minimal 5.28 |
| R-26 | PASS | Handler form/transisi existing dipertahankan; reset dan filter diuji |
| R-27 | PASS | Suite memeriksa loading, empty, error/retry; feedback reset berlabel |
| R-28 | N/A | Aplikasi tidak memiliki FAQ baru |
| R-32 | PASS | Tab/Enter toggle password dan Escape dialog lulus; fokus Material tetap terlihat |
| R-33 | PASS | Source diedit langsung; script aset hanya melakukan resampling PNG |
| R-34 | N/A | Tema terang sesuai brief, tidak menambah toggle tema |
| R-35 | PASS | Flutter dijalankan melalui widget tests, interaksi perubahan direkam dalam tes, APK dibangun |
| R-36 | PASS | Tidak ada klaim security/performance baru; ukuran aset berasal dari file |
| R-37 | PASS | Design Read dan dials tercatat sebelum perubahan |
| R-38 | PASS | Konten fixture hanya pada tests dan screenshot berlabel, tidak dimasukkan production |
| R-39 | PASS | Kontrol Flutter native, label input/tooltip existing, dekorasi ExcludeSemantics; tanpa animasi baru |
| R-40 | PASS | Ukuran gambar direncanakan, decode dibatasi; tidak membuat angka performa tanpa pengukuran |

Border kontrol/putih 4.76:1; navy/off-white 10.99:1; blue/blue-surface
4.75:1. Border kartu netral adalah pemisah dekoratif, bukan satu-satunya tanda
kontrol. Disabled states tidak dipakai sebagai teks instruksi aktif.

## Purpose gate

| Aturan | Status | Alasan |
| --- | --- | --- |
| R-01 | PASS | Tidak menambah gradient/glow layout; shading ilustrasi mendefinisikan objek |
| R-04 | PASS | Ikon calendar, kendaraan, tool, receipt, dan stok sesuai fungsi |
| R-06 | PASS | Roboto existing, ukuran bertingkat untuk judul/bagian/data |
| R-07 | PASS | Tidak menambah grid atau pola latar dekoratif |
| R-08 | PASS | Chevron menunjukkan buka detail; tombol submit tidak diberi panah dekoratif |
| R-09 | PASS | Badge hanya menampilkan status model/akun/stok |
| R-10 | PASS | Tidak ada glassmorphism |
| R-12 | PASS | Kartu data memakai border dan elevasi nol |
| R-13 | PASS | Tidak menambah glow kontrol |
| R-14 | PASS | Hero, statistik ringkas, record, dan section dibedakan sesuai isi |
| R-19 | PASS | Tidak menambah entrance/loop dekoratif; loading mencerminkan proses |
| R-22 | PASS | Ilustrasi otomotif, stok, dokumen, verifikasi sesuai konteks halaman |

## Liveliness

| Item | Status | Bukti |
| --- | --- | --- |
| Dials eksplisit | PASS | ENERGY 2 / RHYTHM 1 / MOTION 1 |
| Konsistensi dials | PASS | Pola form/kartu stabil, warna/ilustrasi sebagai identitas, motion Material |
| Focal point | PASS | Form auth, CTA booking, antrean admin, tugas aktif teknisi |
| Whitespace struktural | PASS | Skala spacing memisahkan kelompok form dan bagian data |
| Aksen disengaja | PASS | Amber kecil pada ilustrasi dan status perhatian |
| Motif identitas | PASS | Gear/wrench, palet biru, keluarga ilustrasi otomotif |
| Design Read | PASS | Tercatat pada laporan beserta alasan tiap keputusan utama |

## Craftsmanship dan quality locks

| Aturan | Status | Bukti/alasan |
| --- | --- | --- |
| C-1 | PASS | Keputusan warna/layout/type/spacing/kartu/aset diberi alasan |
| C-2 | PASS | Tes workflow dan shortcut, reset, filter, serta keyboard lulus |
| C-3 | PASS | Urutan admin/teknisi/pelanggan mengikuti tugas dan data role |
| C-4 | PASS | Reflow, keyboard, state data, dan scroll diperiksa dalam scope Flutter |
| C-5 | PASS | Tidak menambah klaim, statistik, atau profil rekaan |
| R-05 | PASS | Antrean admin dan tugas teknisi memiliki urutan berbeda; tidak memakai template pemasaran |
| R-11 | PASS | Radius input 12, kartu 16, hero 24; pill untuk badge status |
| R-15 | PASS | CTA spesifik: Booking Servis, Kirim Tautan, Kelola Booking, Pekerjaan Saya |
| R-16 | PASS | Copy menjelaskan kegiatan bengkel, tanpa buzzword pemasaran |
| R-20 | PASS | Identitas gear/wrench dan aset mobil/motor konsisten |
| R-21 | PASS | Tema terang ditetapkan brief dan referensi |
| R-29 | PASS | Navy/blue, neutral, amber; warna status punya fungsi semantik |
| R-30 | PASS | Mengikuti referensi BengkelKu pengguna, tidak meniru produk lain |
| R-31 | PASS | Tabel keputusan satu baris pada laporan utama |

Gate ini tidak menyatakan kesamaan piksel, WCAG conformance menyeluruh,
atau keberhasilan native UAT. Batas tersebut tetap berlaku meskipun gate
perubahan lokal lulus. Perbedaan sah dari mockup dicatat pada
[laporan utama](UI_VISUAL_FIDELITY_REPORT.md).
