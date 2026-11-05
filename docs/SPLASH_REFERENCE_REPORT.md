# Splash sesuai papan Auth

Permintaan 5 November 2026: ikuti splash pada ponsel paling kiri di papan
Auth pengguna, dengan logo gear/wrench terbaru. Login, register, dan ikon
launcher tetap memakai identitas terbaru yang sudah ada.

Design Read: layar pembuka untuk pengguna bengkel, bahasa visual otomotif
biru dan fotografis sesuai referensi. ENERGY 2 / RHYTHM 1 / MOTION 1.

## Komposisi

| Keputusan | Alasan dan penerapan |
| --- | --- |
| Gradient biru penuh | Menyamakan bidang identitas pada splash referensi |
| Gear samar di kanan atas | Mengikuti motif latar referensi, tidak menjadi kontrol |
| Logo putih | Siluet master terbaru dipertahankan; warna dibalik agar terbaca pada biru |
| BengkelKu dan subtitle putih | Wordmark dipusatkan pada posisi proporsional terhadap tinggi layar |
| Mobil putih dan motor biru realistis | Mengganti ilustrasi kartun khusus splash agar sesuai subjek referensi |
| Tiga lapis wave | Kurva digambar langsung agar posisi dan warna dapat dituning tanpa artefak raster |
| Loading tanpa tombol atau spinner | Tampilan referensi tidak memiliki kontrol; screen reader tetap menerima status loading |
| Bootstrap dan sesi | Komposisi yang sama tampil selama inisialisasi Firebase dan pemuatan sesi; tanpa timer tambahan |
| Lebar dibatasi pada landscape | Menjaga subtitle besar tidak bertabrakan dengan kendaraan |

Wordmark diperlakukan sebagai logotype dengan ukuran stabil; subtitle
mengikuti text scaling sistem. Gambar dekoratif tidak dibaca berulang oleh
screen reader. Area artwork mengisi layar termasuk di belakang status bar;
ikon status bar berasal dari OS, bukan teks 9:41 atau ikon palsu dari poster.

## Aset dan reproduksi

- Master logo: `assets/branding/emblem-mockup.png`, tidak diganti lagi.
- Aset baru: `assets/illustrations/splash-vehicles.png`, PNG alpha 1152x648.
- Generasi memakai built-in ImageGen dan papan Auth sebagai referensi.
- Aset kendaraan untuk halaman lain tetap `vehicles.png`.
- Source: `lib/core/widgets/session_splash.dart`.
- Render Flutter: `docs/screenshots/visual-fidelity/splash-reference.png`,
  viewport 331x699dp, raster 3x. Ini render widget, bukan screenshot perangkat.
- Render export: `docs/screenshots/visual-fidelity/splash-native.png`,
  viewport 390x824dp, raster 3x, font Roboto dari SDK Flutter.

Ringkasan prompt generasi final:

> Use the supplied Auth poster as the reference. Recreate only the realistic
> vehicle pair from the leftmost splash: a white Toyota-style compact MPV,
> front three-quarter view facing left, with a blue scooter in the foreground
> on the right facing right. Match the reference camera, relative scale and
> overlap. Car about 70% of the width, scooter about 36%. Photographic cutout,
> complete vehicles and wheels, subtle contact shadows, tight 3% safe margins,
> wide 16:9 canvas, genuinely transparent background. No phone, UI, waves,
> wordmark, lettering, rider or extra objects.

Jalankan berurutan, jangan bersamaan dengan proses `flutter test` lain:

```powershell
flutter test test/session_splash_test.dart --dart-define=CAPTURE_UI=true
Copy-Item build/splash-evidence/splash-native.png docs/screenshots/visual-fidelity/splash-native.png
Copy-Item build/splash-evidence/splash-reference.png docs/screenshots/visual-fidelity/splash-reference.png
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export-reference-splash.ps1
```

Export native memakai render yang sama: Android sebelum 12 berupa bitmap
full-screen; iOS LaunchImage 390x824, 780x1648, dan 1170x2472 dengan constraint
ke empat tepi. Bitmap native mengikuti rasio layar dengan scale-to-fill;
landscape native belum diuji. `export-mockup-brand.ps1` kini memanggil export
splash sehingga regenerasi ikon tidak mengembalikan splash logo lama.

Android 12+ menampilkan layar pembuka sistem dengan logo putih dan latar
biru, lalu komposisi Flutter. API sistem hanya menyediakan warna opaque
untuk bidang latar; kendaraan dan wave lengkap muncul pada frame Flutter.
Lihat [dokumentasi Android](https://developer.android.com/develop/ui/views/launch/splash-screen).

## Validasi dan batas

Tes splash memeriksa full bleed, label loading, tidak ada spinner/scroll,
dan pemisahan wordmark, subtitle, dan kendaraan pada 320x568, 360x800,
390x844, 430x932, serta 800x600dp dengan teks 100% dan 200%. Tes sesi existing
memastikan pengguna diteruskan ke route role dan tidak dilogout oleh splash.
`flutter analyze` lulus tanpa issue (`build/splash-analyze.log`, 130.1 detik).
Seluruh 101 tes lulus (`build/splash-tests.log`, 88 detik). Capture khusus
splash juga lulus (`build/splash-capture.log`, dua tes). Formatter memeriksa
lima file Dart yang diedit tanpa perubahan; `git diff --check` lulus.
`flutter build apk --debug` lulus dalam 528.9 detik (`build/splash-apk.log`).
APK: `build/app/outputs/flutter-apk/app-debug.apk`, 216,241,215 byte,
SHA256 `752140615A640CD67F3782869DDA8A99789B26D78011ECB3AB51DDB4D49CE3CC`.
PNG kendaraan, scene native, dan emblem putih ditemukan di dalam ZIP APK;
hash masing-masing identik dengan source. Delapan XML native berhasil
diparse, dan dimensi ketiga LaunchImage iOS sesuai export. Logo putih native
juga diperiksa dengan komposit latar biru. Ini pemeriksaan artifact, bukan
pengganti native UAT. Warning existing KGP Firebase, native access Java, dan
SDK XML tetap ada pada build; dependency/toolchain tidak diubah.

Perubahan hanya dikomit ke `main`; tujuh registrant platform lokal milik
pengguna tidak ikut staged. Dua file Windows yang memiliki perubahan konten
tetap memiliki SHA256 baseline yang sama sesudah build. Phase 07 tidak
dimulai dan tidak ada deployment production.

Pemeriksaan visual dilakukan terhadap poster yang dilampirkan. Kendaraan
adalah hasil generasi ulang, bukan potongan file desain asli. Tidak mengklaim
kesamaan piksel 100%. Native UAT Android dan build/render iOS belum dijalankan
karena tidak ada emulator/perangkat Android dan host ini Windows.

## Delivery gate perubahan splash

| Blok | Status | Bukti |
| --- | --- | --- |
| R-02 | PASS | Dua teks splash tanpa em dash |
| R-03 | PASS | Sepuluh kombinasi ukuran/skala diuji; subtitle tidak bertabrakan dengan kendaraan |
| R-17 | PASS | Tidak menambah statistik |
| R-18 | PASS | Tidak menambah profil atau testimonial |
| R-23 | PASS | Generasi semua aset diminta eksplisit oleh pengguna |
| R-24 | N/A | Splash tidak memiliki navigasi interaktif |
| R-25 | PASS | Batas warna konservatif pada area teks memberi kontras putih 4.53:1, perhitungan di bawah |
| R-26 | PASS | Tidak menambah kontrol; transisi mengikuti state autentikasi yang diuji |
| R-27 | PASS | Splash adalah loading; error Firebase dan retry existing dipertahankan |
| R-28 | N/A | Tidak ada FAQ |
| R-32 | N/A | Tidak ada elemen yang perlu difokuskan pada splash |
| R-33 | PASS | Widget dan native XML diedit langsung, script hanya mengolah export PNG |
| R-34 | N/A | Tidak ada toggle tema; native day/night memakai resource splash yang sama |
| R-35 | PASS | Render Flutter, analyze, 101 tes, dan APK debug lulus; tiga aset APK cocok dengan source |
| R-36 | PASS | Tidak menambah klaim keamanan/performa |
| R-37 | PASS | Design Read dan dials tertulis sebelum implementasi |
| R-38 | PASS | Kendaraan hanya ilustrasi produk, bukan klaim kendaraan atau pelanggan nyata |
| R-39 | PASS | Status loading semantik; gambar dikecualikan dari screen reader; tanpa animasi baru |
| R-40 | PASS | Ukuran gambar dicadangkan; decode mengikuti ukuran render dan device pixel ratio |
| R-01 | PASS | Gradient mempertahankan bidang identitas dari referensi |
| R-04 | PASS | Gear/wrench relevan dengan bengkel dan mengikuti brand terbaru |
| R-06 | PASS | Roboto dan skala wordmark mengikuti hierarki referensi |
| R-07 | PASS | Gear samar berasal dari motif referensi; tidak ada grid dekoratif |
| R-08 | N/A | Tidak ada tombol/panah |
| R-09 | N/A | Tidak ada badge |
| R-10 | N/A | Tidak ada glassmorphism |
| R-12 | N/A | Tidak ada kartu/elevasi |
| R-13 | N/A | Tidak ada glow |
| R-14 | N/A | Tidak ada grid fitur |
| R-19 | PASS | Tidak menambah animasi/timer dekoratif |
| R-22 | PASS | Mobil dan motor dibuat khusus mengikuti kendaraan pada referensi |
| Liveliness | PASS | Dials eksplisit; wordmark focal point; ruang tengah dan aksen kendaraan sesuai papan |
| C-1 | PASS | Alasan tiap keputusan utama ada pada tabel komposisi |
| C-2 | PASS | Tidak ada kontrol mati; session redirect lulus tes existing |
| C-3 | PASS | Hanya identitas dan subjek kendaraan yang diminta pada referensi |
| C-4 | PASS | Full bleed dan text reflow lulus; keterbatasan native UAT dicatat terpisah |
| C-5 | PASS | Tidak menambah testimonial, statistik, atau klaim |
| R-05 | PASS | Tidak menambah template halaman pemasaran |
| R-11 | N/A | Tidak ada tombol/kartu/pill baru |
| R-15 | N/A | Splash tidak memiliki CTA |
| R-16 | PASS | Copy tetap nama dan deskripsi aplikasi dari referensi |
| R-20 | PASS | Gear/wrench, kendaraan realistis, dan wave membentuk motif otomotif |
| R-21 | PASS | Latar biru splash diminta langsung oleh pengguna |
| R-29 | PASS | Biru, putih, dan warna natural kendaraan; tidak menambah palet UI |
| R-30 | PASS | Mengikuti papan BengkelKu pengguna |
| R-31 | PASS | Alasan singkat tiap keputusan tercatat pada tabel komposisi |

Kontras dihitung pada bidang biru di belakang teks. Ambil posisi gradient
konservatif t=0.67 pada stop 0.53 ke 1, campur #1B5AB6 ke #329DF5, lalu
tambahkan opacity gear putih 16/255. RGB hasil 47.73/119.06/204.17 memberi
rasio putih 4.53:1 dengan luminance sRGB linear. Area teks pada ukuran yang
diuji berada sebelum batas t tersebut. Ini pemeriksaan lokal, bukan klaim
WCAG conformance seluruh aplikasi; wave terang tidak memuat teks.
