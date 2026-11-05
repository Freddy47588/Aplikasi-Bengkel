# Aset generated untuk mockup

> Tambahan 5 November 2026: `splash-vehicles.png` dibuat lewat built-in
> ImageGen untuk mobil putih dan motor biru realistis pada splash. Wave
> splash digambar sebagai kurva, dengan master logo terbaru versi putih.
> Prompt, export native, dan render ada pada [laporan splash](SPLASH_REFERENCE_REPORT.md).

Pembaruan audit pada `main`: lihat [laporan visual fidelity](UI_VISUAL_FIDELITY_REPORT.md)
untuk manifest terbaru. Bentuk aset existing dipertahankan kecuali ilustrasi
kendaraan yang dibuat ulang; resolusi PNG diperkecil. Instruksi lanjutan
meminta logo sederhana: master gear/wrench kini dibuat ulang dan semua native
icon diekspor kembali. Total aset aktif kini 6.32MB.
Daftar di bawah menyimpan riwayat generasi awal.

Seluruh aset berikut dibuat dengan tool ImageGen pada sesi pekerjaan ini,
bukan diambil dari situs stok. Output PNG transparan disimpan di repository.
Logo mengikuti brief gear/wrench mockup pengguna; bukan logo geometri lama.

| File | Subjek dan penggunaan |
| --- | --- |
| `assets/branding/emblem-mockup.png` | Gear biru dan wrench; app, PDF, sumber launcher |
| `assets/illustrations/wave.png` | Tiga lapis gelombang biru di kaki layar |
| `assets/illustrations/vehicles.png` | Mobil dan motor; splash/dashboard pelanggan |
| `assets/illustrations/garage.png` | Bengkel; dashboard admin |
| `assets/illustrations/technician.png` | Teknisi; dashboard dan manajemen teknisi |
| `assets/illustrations/booking.png` | Kalender dan tanda konfirmasi; booking |
| `assets/illustrations/checklist.png` | Clipboard pemeriksaan; order/checklist |
| `assets/illustrations/spareparts.png` | Toolbox/sparepart; inventory |
| `assets/illustrations/oil.png` | Wadah oli; detail stok bernama oli |
| `assets/illustrations/verification.png` | Amplop dan centang; verifikasi email |
| `assets/illustrations/password.png` | Kunci/password; reset email berhasil |
| `assets/illustrations/report.png` | Dokumen laporan; invoice/laporan |
| `assets/illustrations/completion.png` | Dokumen servis selesai; riwayat |
| `assets/illustrations/ledger.png` | Catatan pergerakan stok; ledger |
| `assets/illustrations/lock.png` | Gembok; keamanan profil |

## Prompt set

Berikut ringkasan prompt yang dapat digunakan untuk membuat varian, bukan
jaminan regenerasi piksel identik. Setiap subjek dibuat sebagai aset terpisah.

**Gaya bersama:** isolated illustration for BengkelKu mobile automotive
workshop UI, matching the user's blue-and-amber mockup boards. Clean polished
2.5D vector-like illustration, rounded bevels, soft restrained shading,
royal-blue #2563EB, dark steel-navy #1E3A5F outlines and tires, white highlights,
tiny amber #F59E0B attention rays. Pale translucent blue oval cloud accents,
generous negative space, no harsh drop shadow. Wide landscape composition,
subject fully visible centered, tight useful artwork, canvas 3:2 or 16:9.
Real transparent alpha outside artwork. No text, letters, watermark, phone
frames, UI, labels, or background-filling gradients. Friendly Indonesian
workshop app reference. Subject: [subjek pada tabel].

Untuk simbol dokumen, checklist, toolbox, kunci, dan verifikasi: keep it simple
like a large app icon, not a realistic scene; minimal main symbols; no outer
glow or dark haze.

**Logo:** blue circular gear with ten teeth, white inset, wrench crossing
lower-left to upper-right, matching mockup blue automotive identity; centered,
transparent background, no wordmark, no hexagon, no surrounding UI.

**Wave:** three layered blue waves, pale rear to sky-blue front, wide 3:1
composition, reach both side edges and bottom edge, transparent above the
wave, no text, no scene, no shadow.

## Export dan ukuran

PNG sumber dipertahankan; widget memakai cacheHeight/cacheWidth sesuai ukuran
render untuk mengurangi memori decode. Wave 2172x724, logo 1280x1280, ilustrasi
umumnya 1536x1024. Total sumber sekitar 20MB; ukuran ini menambah bundle.

`tools/export-mockup-brand.ps1` menurunkan logo generated ke semua ukuran
launcher Android/iOS existing dan launch image. Jalankan dari Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/export-mockup-brand.ps1
```

Script hanya melakukan export/resampling aset logo yang sudah dibuat.
Launcher iOS memakai latar off-white opaque. Native launch memakai emblem,
sementara splash sesi Flutter menambahkan wordmark dan ilustrasi kendaraan.
Aset branding lama tetap tersedia sebagai arsip; generator geometri lama
`generate-brand-assets.ps1` tidak digunakan untuk identitas mockup ini.
