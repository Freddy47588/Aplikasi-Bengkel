# Phase status - BengkelKu

> Dokumen ini menyimpan audit historis Phase 01. Finalisasi Phase 01 sudah merged
> ke main fork melalui PR #2 pada `9413c42`. Status implementasi terbaru berada di
> [laporan Phase 02](PHASE_02_REPORT.md); setup backend dan batas acceptance ada di
> [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

Tanggal audit: 15 Oktober 2026, Asia/Jakarta. Scope berhenti pada Phase 01.
Branch existing: `fix/mobile-foundation`; base PR: `Freddy47588:main`.

## Hasil terverifikasi

| Pemeriksaan | Hasil nyata |
| --- | --- |
| Audit commit `522541d` | Implementasi existing dipertahankan; PR fork #1 sudah merged pada `d16c0d5` |
| flutter pub get | PASS, tanpa penambahan Firebase atau upgrade dependency |
| flutter analyze | PASS, No issues found |
| flutter test | PASS, 21 tests |
| flutter build apk --debug | PASS; build awal 286.9 detik, build final 23.6 detik |
| APK final | `build/app/outputs/flutter-apk/app-debug.apk`, 157,731,633 byte |
| APK manifest (aapt) | package `id.bengkelku.mobile`, label `BengkelKu`, activity `id.bengkelku.mobile.MainActivity` |
| Native iOS | **NOT VERIFIED**, host Windows tanpa Mac/Xcode |
| Desktop/web | Target dipertahankan; build tidak diuji pada audit ini |

SHA256 APK final:
`5AB52C0EAAB33BD238BA18BC649997A63215BE492F91FC8F2FB7B7E78D23687D`.
APK/log/cache lokal tidak dikomit. Metadata Kotlin lokal diabaikan.

## Acceptance demo

- Login/logout Pelanggan, Teknisi, Admin; guest redirect dan guard role lokal lulus.
- Customer submit melalui form -> Admin confirm -> Customer melihat status -> cancel lulus.
- Admin reject -> Customer melihat Ditolak dan tidak ditawari cancel lulus.
- Repository menguji duplikat, ownership, transisi terminal dan stream dua subscriber.
- System back detail Customer/Admin menuju daftar; selectedIndex detail sesuai role.
- Layout login dan halaman utama: 320/360/390/430dp serta 1280dp, text scale 1.3.
- Keyboard 250px di 320x568 pada text scale 1.3; keluhan dan submit dapat discroll.
- Review/kirim keluhan 500 karakter di 320dp pada text scale 1.3 lulus.
- SafeArea tetap dipakai di halaman mobile; hasil widget bukan bukti perilaku native iOS.

## Batas dan tindak lanjut

Demo tetap in-memory per proses; restart menghapus booking dan tidak sinkron lintas
perangkat. Guard lokal bukan otorisasi backend. Identifier sumber dipertahankan;
kepemilikan/registrasi eksternal belum diverifikasi. Signing rilis dan native iOS
memerlukan lingkungan serta kredensial asli pada fase berikutnya.

Perubahan Firebase belum di-commit pada checkout `feat/firebase-auth-booking` tidak
disentuh dan tidak dinyatakan selesai. Tidak ada Firebase, inventori atau pembayaran
produksi yang dibuat oleh audit ini. Lihat [ROADMAP.md](ROADMAP.md) untuk rencana.

PR review wajib sebelum merge; tidak ada auto-merge, force push atau push ke upstream.
Commit, hasil push dan URL PR dilaporkan pada respons penyelesaian.

## Smoke Android native (terbatas)

Emulator existing `Pixel_6`, Android 17/API 37 x86_64, 1080x2400, density 420,
font scale 1.3. APK final dipasang dengan `adb install --no-streaming -r` (Success).
Install streaming awal lambat dan dihentikan sebelum mencoba push install.
Startup default sempat timeout, Pixel Launcher menampilkan ANR dan layar menjadi
hitam. Software rendering saja gagal karena Impeller tidak mendukungnya.

Workaround lokal yang berhasil (tanpa mengubah manifest/source):

```sh
adb shell am start -n id.bengkelku.mobile/.MainActivity --ez enable-software-rendering true --ez enable-impeller false
```

UIAutomator membuktikan layar Mode Demo, login Pelanggan -> dashboard -> Booking,
input `Rem_berbunyi` ke keluhan dan perubahan viewport saat keyboard, tutup keyboard,
Profil -> Keluar, login Teknisi -> Pekerjaan (Demo), Profil -> Keluar, login Admin
-> daftar Booking kosong. Screenshot lokal Admin ditinjau; tidak terlihat overflow.
XML/screenshot berada di `build/bengkelku-*` dan tidak dikomit.

**Status: PARTIAL PASS**. Install, UI role dan navigasi dasar lulus dengan workaround;
rendering default dan cold-start stabil belum terbukti pada emulator ini. Alur
submit/confirm/reject/cancel native belum diulang penuh; buktinya adalah widget/unit
tests. Perlu ulang smoke pada emulator stabil/HP dengan rendering default. Tidak
ada perubahan aplikasi yang dibuat hanya untuk menyesuaikan grafis emulator.
