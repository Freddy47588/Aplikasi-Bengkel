# BengkelKu: visual fidelity review

Pekerjaan pada branch `main`, checkout `D:/Portfolio-Projects/Aplikasi-Bengkel`.
HEAD awal setelah fetch/fast-forward aman:
`f6658c73716c048e698343045d7bf99d2bffbd7f`. Tidak membuat branch, worktree,
atau PR baru. Tujuh file registrant platform yang sudah dimodifikasi sebelum
pekerjaan dipertahankan dan tidak termasuk perubahan UI yang akan dikomit.

## Status referensi

Sepuluh papan mockup berhasil dibaca dari lampiran pesan pengguna "nih" pada
sesi ini. Folder `design/mockups/` memang tidak tersedia; sumber referensi
adalah gambar yang ditampilkan dalam percakapan. Blocker awal akses gambar
sudah selesai. Yang dibandingkan adalah UI di dalam ponsel, bukan poster,
bingkai, panel penjelasan, atau legenda palet.

| Kode | Judul papan | Urutan lampiran pada pesan pengguna |
| --- | --- | --- |
| R01 | Auth: Splash, Login, Register | 6 |
| R02 | Akun: Password, Verifikasi, Profil | 1 |
| R03 | Pelanggan: Beranda dan Kendaraan | 8 |
| R04 | Pelanggan: Booking dan Tracking | 7 |
| R05 | Admin: Dashboard dan Booking | 9 |
| R06 | Admin: Teknisi dan Service Order | 3 |
| R07 | Teknisi: Dashboard dan Tugas | 5 |
| R08 | Teknisi: Checklist dan Sparepart | 4 |
| R09 | Sparepart: Inventori dan Stok | 2 |
| R10 | Pembayaran: Invoice dan Laporan | 10 |

## Mapping dan gap matrix

Pemetaan berikut memakai referensi R01 sampai R10 dan model existing sebagai
batas implementasi. Screenshot sebelum/sesudah ditautkan pada indeks visual.

| Kelompok | Layar / file utama | Gap baseline dan perbaikan |
| --- | --- | --- |
| 1 Auth | `login_screen.dart`, `SessionSplash` | Spacing login lebih ringkas; brand, splash tanpa tombol, dan validasi existing dipertahankan |
| 2 Akun | `login_screen.dart`, `profile_screen.dart` | Mode lupa password mempunyai ilustrasi, email dan Kirim Tautan; reset tetap Firebase Auth; profil tidak menambah avatar palsu |
| 3 Pelanggan / kendaraan | `live_dashboard.dart`, `vehicles_screen.dart` | Ilustrasi kendaraan terlalu realistis diganti versi vector-like mobil dan motor; shortcut lebih awal |
| 4 Booking / tracking | `customer_booking_screen.dart`, `foundation_pages.dart`, `service_timeline.dart` | Header lebih padat; kelompok kendaraan/layanan dan jadwal; dropdown wrap; booking ditolak diberi warna bahaya |
| 5 Admin / booking | `live_dashboard.dart`, `foundation_pages.dart` | Hero operasional ringkas; antrean booking tampil sebelum progres/order; data dan query tetap |
| 6 Admin / teknisi / SO | `technicians_screen.dart`, `service_orders_screen.dart` | Filter teknisi bisa dibuka saat diperlukan; daftar terlihat lebih awal; kartu SO menyebut nama teknisi dari data |
| 7 Teknisi / tugas | `live_dashboard.dart`, `service_orders_screen.dart` | Pekerjaan aktif ditempatkan sebelum metrik; tidak ada angka keuangan atau prioritas fiktif |
| 8 Checklist / sparepart | `service_orders_screen.dart`, `order_parts_screen.dart` | Aset diperkecil; wave dilepas dari form; checklist, permintaan dan persetujuan existing dipertahankan |
| 9 Inventori / stok | `inventory_screen.dart` | Ilustrasi pembuka terpusat, filter collapsible, daftar lebih awal, ikon transaksi masuk/pemakaian/koreksi dibedakan |
| 10 Invoice / laporan | `payments_screen.dart`, `invoice_pdf.dart` | Header daftar lebih ringkas, border kartu netral, wave dilepas; perhitungan dan logo PDF existing dipertahankan |

Seluruh layar existing dari mapping sebelumnya ditinjau lewat sumber dan
render fixture yang tersedia. Form/dialog/transaksi yang tidak memerlukan
perubahan struktur tetap memakai komponen Material dan tema bersama.

## Design Read dan keputusan

Aplikasi manajemen bengkel untuk pelanggan, admin, dan teknisi; bahasa visual
otomotif profesional, ENERGY 2 / RHYTHM 1 / MOTION 1. Perbedaan urutan konten
per role mengikuti tugasnya; pola navigasi dan kontrol tetap konsisten.

| Keputusan | Alasan |
| --- | --- |
| Navy, Royal Blue, amber, off-white | Mengikuti identitas yang ditetapkan pada brief |
| Kartu umum border `#E2E8F0`, hero border `#BFDBFE` | Memisahkan data operasional dari panel informasi |
| Roboto existing | Tetap terbaca dan tidak menambah font/dependency |
| Heading halaman 24sp, bagian 20sp, kartu 16sp | Memperjelas hierarki tanpa membesarkan seluruh teks |
| Padding halaman 20dp; skala 4/8/12/16/20/24/32 | Menghubungkan kontrol dalam kelompok dan memisahkan bagian |
| Radius input 12, kartu 16, hero 24 | Memberi hirarki bentuk tanpa semua elemen menjadi pill |
| PageIntro memakai ilustrasi terpusat 104dp | Mengikuti komposisi papan tanpa mengulang judul yang sudah ada di app bar |
| Hero admin/teknisi menempatkan ilustrasi di samping | Mendahulukan antrean/tugas pada layar pertama |
| Ilustrasi dekoratif disembunyikan pada teks di atas 130% | Memprioritaskan ruang untuk informasi dan kontrol |
| Wave hanya pada splash/login/beranda pelanggan | Menjaga motif brand tanpa mengurangi area kerja tiap form |
| Warna status selalu ditemani label | Status tidak bergantung pada persepsi warna |
| Tidak menambah animasi | Operasional membutuhkan respon langsung; transisi Material tetap |
| Tema terang dari brief | Mengikuti referensi off-white yang diminta; tidak menambah mode parsial |

## Manifest aset

ImageGen built-in dipakai untuk satu pengganti ilustrasi kendaraan dan,
sesuai instruksi lanjutan pengguna, satu logo gear/wrench yang lebih sederhana.
Ilustrasi lain dipertahankan bentuknya. Optimisasi resolusi
dilakukan deterministik lewat `tools/optimize-workshop-assets.ps1`, tanpa
dependency runtime. Alpha PNG dipertahankan. Logo baru dipakai konsisten pada
app, PDF, launcher dan splash. Identitas gear/wrench serta warna biru tetap.

| Status | Aset | Hasil |
| --- | --- | --- |
| GENERATED + REFINED | `assets/illustrations/vehicles.png` | Mobil dan scooter biru vector-like, 864x576, komposisi berimbang |
| REFINED | `booking`, `checklist`, `completion`, `garage`, `ledger`, `lock`, `oil`, `password`, `report`, `spareparts`, `technician`, `verification` di `assets/illustrations/` | Subjek dipertahankan, resolusi 864x576 |
| REFINED | `assets/illustrations/wave.png` | Bentuk dipertahankan, 1296x432 |
| GENERATED + REFINED | `assets/branding/emblem-mockup.png` | Gear sederhana, wrench sepenuhnya di dalam gear; 512x512 |
| REUSED | Ikon Material dan `BrandLockup` | Ikon aksi dan wordmark tetap |
| REFINED | Native launcher/splash Android/iOS | Export baru dari logo sederhana dengan padding aman |
| NOT NEEDED | Ilustrasi kosong/error/loading tambahan | State berlabel dan ikon existing sudah mencukupi |
| NOT NEEDED | Avatar/telepon/alamat, grafik statistik baru | Tidak didukung kebutuhan/model existing |
| BLOCKED | Tidak ada generasi aset yang terblokir | Semua aset yang diperlukan sudah tersedia |

Total 15 PNG aktif setelah optimisasi: **6,321,020 byte**, dibanding
21,018,317 byte sebelumnya (sekitar **69.9% lebih kecil**). Ini ukuran file
aset, bukan klaim persentase penghematan APK atau performa runtime.
`cacheHeight/cacheWidth` existing tetap membatasi decode ke ukuran render.

Prompt final ImageGen:

> One isolated production illustration for BengkelKu: unbranded compact blue
> car and blue Indonesian-style scooter beside each other, equal emphasis,
> fully visible. Clean premium 2.5D vector-like app illustration matching
> rounded calendar/toolbox/clipboard icons; simplified broad geometric forms,
> crisp moderate navy outlines; Royal Blue #2563EB, Steel Navy #1E3A5F,
> white highlights, restrained Amber #F59E0B. Soft controlled matte shading,
> landscape 3:2, tight safe padding, transparent alpha, pale blue oval accent.
> No photorealism, detailed chrome, vehicle brands, text, registration numbers,
> UI, phone mockup, people, background gradient, ground haze, or outer glow.

Output asli generator disimpan di `.codex/generated_images/`; output final
yang digunakan aplikasi berada di repository, tidak bergantung pada folder
generator. Aset transparan diperiksa di atas putih secara individual melalui
contact sheet dan dibandingkan dengan keluarga ilustrasi pada papan asli.

Instruksi lanjutan pengguna meminta merapikan ikon APK dan membuat ulang logo
yang simpel. Logo baru menghapus lingkaran putih besar, handle yang keluar,
dan detail glossy. Prompt: minimal Royal Blue eight-tooth gear, white wrench
fully inside, crisp flat geometric mark, no gradient/shadow/text/3D/tile,
transparent canvas with 15% safe margin. Hasil disimpan pada path logo yang
sama agar semua pemakai termasuk PDF memakai satu identitas.

`tools/export-mockup-brand.ps1` mengekspor seluruh density Android dan ukuran
iOS. Skala export sekarang 1 karena padding aman sudah ada di master.
`tools/preview-launcher-icons.ps1` memeriksa radius alpha foreground pada layer
72dp: **27.19dp**, di dalam radius aman 33dp. Angka ini pemeriksaan geometri
source, bukan klaim native runtime. [Panduan adaptive icon Android](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
menetapkan layer 108dp dan area aman 66dp. Simulasi circle, rounded square,
squircle, dan legacy tersedia pada `docs/screenshots/visual-fidelity/launcher-preview.png`.

## Before / after dan rubric

Baseline dari HEAD awal tersedia di
`docs/screenshots/visual-fidelity/before/`. After dirender ulang dari widget
Flutter pada viewport **390x740dp**, text scale **100%**, PNG **780x1480**.
Data semuanya fixture. Ini bukan screenshot emulator/perangkat asli.
Tersedia 36 baseline dan 37 after; tambahan satu after merekam sukses reset.

Indeks perbandingan ada pada
`docs/screenshots/visual-fidelity/README.md`.

Rubric yang diminta: layout 30%, tipografi 15%, warna 15%, ikon/ilustrasi 15%,
komponen/spacing 15%, responsivitas/aksesibilitas 10%. Penilaian berikut
**manual dan subjektif**, skala 1 sampai 5. Angka akhir adalah jumlah skor
berbobot dibagi 5, bukan pengukuran kesamaan piksel atau hasil alat otomatis.

| Kelompok | Layout | Tipe | Warna | Aset | Spacing | Akses | Nilai /100 | Alasan utama |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Auth | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Struktur login/register sesuai; splash off-white mengikuti brief tertulis |
| Akun | 3 | 4 | 4 | 4 | 4 | 4 | 74 | Reset kini dekat referensi; profil tanpa avatar dan reset baru via Firebase |
| Pelanggan | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Kendaraan berimbang, daftar dan shortcut konsisten; field hanya yang tersimpan |
| Booking | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Header terpusat, kelompok form jelas, timeline state nyata |
| Admin dashboard | 3 | 4 | 4 | 4 | 4 | 4 | 74 | Komposisi operasional lebih padat; metrik dibatasi query existing |
| Admin teknisi / SO | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Daftar muncul lebih awal, teknisi tercantum, detail terkelompok |
| Teknisi dashboard | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Tugas aktif jelas; ringkasan bukan total harian fiktif |
| Checklist / sparepart | 3 | 4 | 4 | 4 | 4 | 4 | 74 | Kontrol dan ilustrasi seragam; checklist/permintaan mengikuti model existing |
| Inventori | 4 | 4 | 4 | 4 | 4 | 4 | 80 | Filter ringkas, badge nyata, ruang daftar bertambah |
| Pembayaran | 3 | 4 | 4 | 4 | 3 | 4 | 71 | Invoice terkelompok; layar admin tetap lebih padat karena kontrol laporan/terbit existing |

Gap yang sengaja dipertahankan: navigasi empat tab existing, metode pembayaran
manual, tidak ada konfirmasi password tambahan pada register, tidak ada avatar
atau nomor telepon fiktif, tidak ada notifikasi tanpa backend, dan tidak ada
angka/grafik contoh dari poster. Form membuat password baru dikelola lewat
tautan Firebase; tidak dibuat form lokal yang melewati alur itu. Checklist
tidak ditambah item oli/rem/lampu tanpa model. Wave tidak dipasang di semua
halaman operasional agar tidak mengurangi ruang kerja. Native launch memakai
logo tanpa penundaan; splash sesi mengikuti loading sebenarnya.

## Quality gate dan batas validasi

| Pemeriksaan | Hasil dan bukti |
| --- | --- |
| `flutter pub get` | PASS, `pub-get.log`, tidak mengganti dependency |
| Formatter | PASS, 74 file, 0 perubahan pada pemeriksaan akhir |
| `flutter analyze` | PASS, No issues found, `final-analyze.log` |
| `flutter test` | PASS, 99 tes setelah logo baru, `logo-tests.log` |
| Render fixture | PASS, 37 after memakai logo terbaru, `logo-capture.log` |
| `flutter build apk --debug` | PASS, 464.4 detik, `logo-apk.log` |
| `git diff --check` | PASS |
| Aset APK | PASS, 15 PNG aktif ditemukan dalam ZIP APK |
| Android device UAT | NOT RUN, tidak ada perangkat/emulator Android |
| iOS build/render | NOT RUN, host Windows tanpa Xcode |
| Native print/share | NOT RUN |

Log ada di `build/visual-fidelity/`. APK lokal
`build/app/outputs/flutter-apk/app-debug.apk`: 216,447,929 byte,
SHA256 `C2CEDFEF46E64DD5EFA982E17760FC4097064D562D3FE689EF1CCD79D5749C92`.
Ukuran APK debug bukan ukuran rilis dan tidak dibandingkan sebagai benchmark
terhadap build lama. Peringatan existing KGP Firebase/native access Java tetap
tercatat, juga warning SDK XML dari command-line tools; migrasi toolchain di
luar scope UI. Backend/schema/rules tidak diubah. Ikon native baru diekstrak
dari APK dan diperiksa; kelima density launcher dan drawable splash tersedia.
Percobaan tes paralel sempat mengalami race pada native-assets cache Flutter;
pengulangan bergiliran berhasil, tanpa perubahan source untuk menutupi error.

Matriks layout mencakup 320/360/390/430/800dp, skala 100/130/200%, keyboard,
scroll, serta state error/empty/loading pada suite existing. Tes baru mencakup
semua shortcut dashboard, filter terbuka pada teks 200%, Tab/Enter untuk form,
toggle password lewat keyboard, reset email, dan Escape menutup dialog.

## Git dan kesiapan Phase 07

HEAD akhir implementasi UI yang diuji:
`c9f7e98baa45b78097867125b2472d12c0694f8c`, commit
`style: improve BengkelKu visual fidelity and illustration assets`, telah
dipush ke `origin/main`. Penyederhanaan logo dan dokumentasi final dikomit
sesudahnya; HEAD akhir seluruh rangkaian adalah commit yang memuat laporan
ini dan SHA-nya dicatat pada respons akhir. Push normal setelah fetch,
tanpa force push; kondisi remote diperiksa lagi setelah push.
Tidak membuat PR baru atau deployment. Phase 07/08 tidak dimulai. UI siap
ditinjau untuk penerimaan, dengan UAT perangkat, iOS, dan print/share native
sebagai pekerjaan verifikasi berikutnya sebelum penerimaan production.
