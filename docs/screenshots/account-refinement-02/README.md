# Akun — Password, Verifikasi, Profil

Audit awal: `9ed49208416a659d5595bab6cc2d110d849530fd` pada branch `main`.
Fetch origin/main berhasil setelah memakai akses jaringan yang diizinkan; HEAD
sesuai remote saat audit. Tujuh generated plugin desktop sudah berubah sebelum
pekerjaan. Byte awal dicadangkan di `build/account-02-local-backup` dan diverifikasi
tetap sama. File tersebut tidak disertakan dalam commit refinement ini.

## Acuan TA dan cakupan F-01

Dokumen ditemukan melalui lampiran percakapan ChatGPT “Revisi Laporan TA” dan
“Pembuatan Laporan TA Word”, sesuai arahan pengguna untuk mencari di ChatGPT.
Sumber yang benar-benar dibaca adalah laporan A5 versi 75 halaman dalam DOCX dan
proposal penelitian 8 halaman dalam PDF. Dokumen asli tidak diubah atau ditambahkan
ke repository. Isi dokumen digunakan sebagai kebutuhan, bukan instruksi operasional
yang menggantikan permintaan pengguna.

Laporan BAB III, Tabel 3.1 menetapkan F-01 “Registrasi, login, profil” untuk semua
pemakai. Bagian 3.4/3.5/3.6 mensyaratkan keamanan per peran, validasi, navigasi dan
akses sesuai kewenangan. Bagian 3.8 menyebut atribut users secara konseptual dan
menegaskan bahwa skema final harus mengikuti implementasi. Bagian 3.10 memerlukan
input autentikasi, validasi, pesan kegagalan dan navigasi sesuai role. Proposal
halaman 5 memisahkan kebutuhan pelanggan, admin/kasir dan teknisi.

| Kebutuhan F-01 | Implementasi yang dipertahankan |
| --- | --- |
| Registrasi dan login | Firebase email/password; registrasi pelanggan, role tepercaya tidak dapat dipilih sendiri |
| Pemulihan akun | `sendPasswordResetEmail`, email dipangkas repository, respons aman terhadap email enumeration |
| Verifikasi | Resend, reload user/token, pemeriksaan ulang status dan refresh saat aplikasi kembali aktif |
| Profil | Email, role, status aktif dan verified dari AuthSession; tanpa identitas atau foto rekaan |
| Hak akses | Guard loading/missing profile/unverified/inactive dan redirect tiga role tetap berlaku |
| Keluar akun | Sign-out existing dengan loading, pencegahan submit berulang dan error feedback |

Repository Auth, model sesi, router, rules, struktur Firestore, transaksi serta
dependency tidak diubah. Pekerjaan Phase 07 dan modul notifikasi tidak disentuh.
QA Gate Phase 07 tetap memiliki batas penerimaan perangkat/UAT yang tercatat pada
`docs/QA_GATE.md`; kelulusan otomatis refinement ini tidak membuka Phase 08.

## Mapping dan bukti screenshot

| Mockup | Layar aktual | Before | After |
| --- | --- | --- | --- |
| Lupa Password | Mode recovery `LoginScreen` | [Before](before/fixture-account-recovery.png) | [After](after/fixture-account-recovery.png) |
| Verifikasi Email | `AccountScreen` untuk sesi aktif yang belum verified | [Before](before/fixture-account-verification.png) | [After](after/fixture-account-verification.png) |
| Profil Saya | `ProfileScreen`, contoh sesi pelanggan | [Before](before/fixture-account-profile.png) | [After](after/fixture-account-profile.png) |
| Buat Password Baru | Action handler pada tautan email Firebase | Tidak ada layar Flutter existing | Tidak dibuat layar Flutter palsu |

Render otomatis widget Flutter pada 390 × 844dp, DPR 2, font Roboto dan Material
Icons asli. Akun `example.test` hanya fixture test; production membaca sesi aktual.
Ini bukan foto perangkat atau bukti pengiriman email produksi. Bingkai iPhone,
Dynamic Island, jam 9:41, judul poster dan panel penjelasan tidak ditiru.

## Perbandingan dan perbaikan visual

Lupa password memakai header putih dengan back, amplop/gembok amber existing,
heading “Lupa Password?”, email rounded dan CTA Kirim Tautan dengan ikon kirim.
Back perangkat mengembalikan mode login; aksi Kembali ke Login existing tetap
tersedia sebagai text button. Input reset memakai validator email formulir yang
lebih lengkap, sambil mempertahankan teks error existing dan respons generik.

Verifikasi berubah dari hero berbentuk panel besar menjadi komposisi ilustrasi,
heading, petunjuk, email aktual, kartu Periksa Kotak Masuk dan bantuan Tidak
menerima email. CTA Kirim Ulang tetap memanggil operasi existing. Periksa ulang
status akun, Keluar, recovery profil yang belum lengkap dan status akun nonaktif
tetap tersedia. Teks awal tidak mengklaim email sudah berhasil dikirim apabila
belum ada hasil operasi; pesan sukses baru muncul setelah callback berhasil.

Profil memakai wave Royal Blue, avatar ikon umum, identitas sesi, kartu informasi,
ubah password, status verifikasi, menu garasi/dokumen pelanggan dan logout outlined
merah. Informasi akun, pemeriksaan verifikasi dan menu tambahan dapat dibuka.
Pada 390dp, menu utama dan logout kini terlihat tanpa melewati panel keamanan
besar seperti before. Pada layar sempit/teks besar, badge verifikasi berpindah
ke bawah judul. Setelah render pertama, lebar header wave diperbaiki agar mengisi
seluruh viewport, bukan hanya selebar avatar.

Palet menggunakan Steel Navy `#1E3A5F`, Royal Blue `#2563EB`, Amber `#F59E0B` dan
off-white `#F8FAFC`. Kartu putih, border biru muda, radius 16dp dan ikon Material
mengikuti keluarga komponen existing. Wave bawah tetap 32dp agar tidak menutup
konten. Ilustrasi disembunyikan pada skala teks di atas 1,3× untuk memberi ruang
pada input dan tindakan.

## Aset serta gap mockup dan kode

- `password.png` dan `verification.png` existing sudah sesuai gaya clean automotive
  2.5D dan dirender tanpa aset rusak. Tidak ada gambar baru atau perubahan branding.
  Avatar dan clip wave header adalah widget/vector Flutter original, bukan foto
  pengguna dan tidak memiliki tombol kamera palsu.
- Tidak ada handler `oobCode`, `verifyPasswordResetCode`, `confirmPasswordReset`
  atau `updatePassword` dalam source Flutter. Aplikasi meminta email reset melalui
  Firebase; password baru disimpan lewat action handler resmi pada tautan tersebut.
  Visual halaman eksternal mengikuti konfigurasi Firebase dan tidak dikendalikan
  penuh oleh Flutter. Tidak ada form yang dapat mengganti password tanpa token.
- AuthSession tidak menyediakan nama, telepon atau foto. Header menggunakan role
  dan email aktual. Atribut konseptual pada laporan tidak ditambahkan ke backend
  hanya demi menyalin mockup.
- Ubah Password mengirim tautan reset untuk email sesi; tidak mengubah password
  langsung. Status verifikasi berasal dari sesi, dan pemeriksaan ulang tetap ada.
- Layout verifikasi lebih rapat karena mempertahankan refresh dan logout yang tidak
  digambarkan pada mockup. Profil pelanggan tetap mempunyai menu kendaraan/invoice
  serta navigasi bawah. Font, avatar ikon dan aset existing tidak identik dengan
  ilustrasi/font pada poster. Tidak ada klaim 100% sama.

## Pengujian dan batas alat

Tes baru memeriksa email tidak valid, submit berulang/loading, error jaringan dan
throttling, resend, lifecycle resume, session refresh, inactive guard, redirect
lintas role, reset dari profil dan logout. Test repository memastikan email reset
dipangkas, user-not-found disamarkan dan error jaringan tetap disampaikan. Guard
loading/missing profile/disabled serta isolasi sesi tetap tercakup tes existing.
Ketiga layar diuji pada 320/360/390/430dp, text scaling 1/1,3/2×, termasuk keyboard
280dp dan section profil terbuka. Lima tes akun final dan capture lulus.

| Pemeriksaan | Hasil aktual |
| --- | --- |
| `flutter pub get` online | Resolusi online tidak selesai pada percobaan awal; tidak diklaim PASS |
| `flutter pub get --offline` | PASS; dependency terkunci tersedia, lockfile tidak berubah |
| `dart format --output=none --set-exit-if-changed .` | Gagal membaca path artefak build lokal lama yang diabaikan Git, bukan error source |
| Format semua source Dart dari daftar Git | PASS, 91 file, 0 perubahan |
| `flutter analyze --no-pub` | PASS, no issues found |
| `flutter test --no-pub --concurrency=2` | PASS, 132 tes |
| `npm run test` | Tidak tersedia: package.json tidak mendefinisikan script test |
| `npm run test:rules -- --config build/inventory-refinement-emulators.json` | PASS, 38 tes, 0 gagal, exit code 0 |
| `flutter build apk --debug --no-pub` | PASS, exit code 0, 116,1 detik |
| `git diff --check` | PASS |
| Infinix/perangkat ADB | NOT RUN; `adb devices -l` tidak menemukan perangkat |
| Native iOS, email produksi, halaman reset eksternal dan UAT | NOT RUN pada sesi ini |

Formatter literal titik tersandung folder lama
`build/unified-splash-validation/source/build/cloud_firestore/...`; artefak itu
tidak dihapus atau dipindahkan. Semua file Dart yang dilacak maupun source baru
yang tidak diabaikan Git diperiksa sebagai pengganti pemeriksaan source lengkap.
Script npm yang benar-benar tersedia adalah test:rules; alias baru tidak ditambah
untuk pekerjaan UI. Log lokal berada di `build/account-02-*.log`.
Tidak ada pengujian tambahan setelah pengguna meminta penghentian pengujian.
Build APK dan hasil tes di atas telah selesai sebelumnya. Warning kompatibilitas
KGP pada plugin Firebase existing tidak menghalangi build; dependency tidak diubah.

## Delivery gate antislop

- Hard Gate PASS: hanya data/aksi aktual, tidak ada OOB handler palsu, field fiktif,
  guard yang dilonggarkan atau perubahan aturan data.
- Purpose Gate PASS: ilustrasi menjelaskan recovery/verifikasi; badge menampilkan
  state nyata; card dan section menjaga informasi akun serta menu existing.
- Liveliness PASS: ENERGY 2 / RHYTHM 2 / MOTION 1; palet dan ilustrasi dari referensi,
  wave terbatas dan tidak ada animasi dekoratif baru.
- Craftsmanship PASS pada cakupan UI otomatis: before/after ditinjau, header wave
  dan overflow badge diperbaiki; keyboard dan teks 2× diuji. Kontrol Material memakai
  label, tooltip dan fokus native; feedback error/sukses menjadi live region.
  Kontras tema: navy/background sekitar 10,99:1, putih/Royal Blue 5,17:1,
  teks sekunder/putih 7,58:1 dan outline kontrol/putih 4,76:1. Status tetap mempunyai
  label teks, bukan warna saja. Batas perangkat dan perintah di atas tetap berlaku.

Regenerasi capture:

```text
flutter test --no-pub --concurrency=1 test/account_refinement_test.dart --dart-define=CAPTURE_UI=true --dart-define=CAPTURE_DIR=docs/screenshots/account-refinement-02/after
```
