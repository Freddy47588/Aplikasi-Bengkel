# Branding BengkelKu — universal blue identity

> Pembaruan 4 November 2026: identitas aktif memakai logo gear/wrench generated
> dari mockup sesuai instruksi pengguna. Lihat [aset mockup](MOCKUP_ASSETS.md)
> dan [laporan alignment](MOCKUP_ALIGNMENT_REPORT.md). Bagian di bawah adalah
> arsip identitas geometri sebelumnya; generator lamanya tidak dipakai untuk
> export identitas aktif.

Emblem baru berupa housing heksagonal Royal Blue yang mengelilingi rotor
enam gigi Off-white, dengan lubang poros heksagonal Steel Navy. Siluet geometris
ini digambar dari koordinat sendiri; bukan recolor atau modifikasi mark B lama.
Nama aplikasi tetap BengkelKu. Tidak memakai artwork atau logo pihak ketiga.

## Aset dan generator

Jalankan dari Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools/generate-brand-assets.ps1
```

Script menetapkan root dari lokasi file (juga menerima `-Root`), menggunakan
System.Drawing dan Segoe UI lokal untuk wordmark. Koordinat yang sama digunakan
untuk SVG, PNG dan Android vector. Tidak mengunduh asset/dependency. Hasil
raster teks dapat berbeda antarversi font/Windows; geometri tetap sama.

| Lokasi | Hasil/referensi |
| --- | --- |
| `assets/branding/emblem.svg` | Master geometri yang dapat ditinjau/diedit |
| `assets/branding/emblem.png` | PNG transparan 512, dibundel pubspec dan dipakai widget/PDF |
| `assets/branding/launcher-master.png` | Master ikon 1024, latar opaque Steel Navy |
| `assets/branding/splash-lockup.png` | Emblem + wordmark transparan |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Ikon legacy 48/72/96/144/192px |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | Adaptive foreground/background |
| `android/app/src/main/res/drawable/brand_emblem.xml` | Vector foreground, juga ikon splash Android 12+ |
| `android/app/src/main/res/values/colors.xml` | Background adaptive Steel Navy |
| `android/app/src/main/res/drawable-*/brand_wordmark.png` | Wordmark splash Android 12+, 5 density |
| `android/app/src/main/res/drawable-nodpi/splash_lockup.png` | Lockup untuk launch background pra-Android 12 |
| `android/app/src/main/res/values-v31/styles.xml` | Splash Android 12+, termasuk wordmark |
| `android/app/src/main/res/values-night-v31/styles.xml` | Splash yang sama pada pengaturan sistem gelap |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | Seluruh ukuran katalog existing, alpha penuh |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | Lockup 200×240, 400×480, 600×720 |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | Latar Steel Navy dan lockup di tengah |

Foreground Android menggunakan canvas 108dp. Seluruh titik emblem berada
dalam radius 32,4dp di pusat canvas sehingga muat di safe circle 66dp. Tidak
ada teks pada launcher icon dan tidak membuat sudut bundar buatan pada iOS.
Android 12 menggunakan ikon sistem dan branding image, bukan splash Flutter
kedua yang menambah waktu tunggu. iOS tetap memakai storyboard existing.

Panduan platform: [Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
[Android splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen),
dan [Apple launch screen](https://developer.apple.com/documentation/xcode/specifying-your-apps-launch-screen).

Konfigurasi applicationId Android `id.bengkelku.mobile`, bundle ID iOS,
Firebase Project `bengkelku-app-bebd9`, serta nama aplikasi tidak berubah.
Build/render iOS harus diverifikasi di macOS/Xcode; audit file pada Windows
tidak membuktikan native launch berhasil.
