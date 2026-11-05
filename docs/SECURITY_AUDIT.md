# Audit keamanan Phase 07

Scope: source Rules, model/repository, konfigurasi Firebase dan seluruh suite
emulator; bukan penetration test production atau audit IAM/Console langsung.
Project asli tidak diubah/deploy. Status paket Spark tidak diubah; billing dan
provider production tidak diperiksa ulang. Hasil run ada di PHASE_07_REPORT.md.

## Kontrol dan cakupan

| Risiko | Bukti otomatis / kontrol |
| --- | --- |
| Anonymous, email unverified, users.active=false | firestore.test: default deny dan deactivation; inventory: akun inactive/unverified |
| Akun Auth disabled | Login ditolak oleh Auth Emulator pada test tambahan; users.active terpisah dari flag Auth |
| Customer baca/tulis milik lain, query tanpa scope | firestore.test, service_orders.test, payments.test; integrasi dengan token Auth asli |
| Teknisi tugas lain / keuangan admin | service_orders.test, inventory.test, payments.test dan integrasi |
| Role escalation, ubah active/owner, extra fields | Registrasi customer-only; users update/delete/list ditolak; allowlist setiap model |
| Admin operasi sah | Katalog, booking, direktori teknisi, SO assignment/pricing, inventory, invoice/payment diuji positif |
| Booking forged/slot ganda/cancel race | firestore.test: canonical lock dan race satu pemenang; service_orders.test: cancel vs create |
| Stock negatif/tanpa ledger/harga palsu | inventory.test: witness dua arah, snapshot, lowStock, race dan reversal |
| Payment palsu/double submit/transfer overpay | payments.test: integer, revisi, audit atomik, replay dan terminal |
| Terminal SO dan audit dihapus | service_orders.test, inventory.test, payments.test; event update/delete denied |
| Field harga beli | Master dan stockMovements admin-only; customer hanya snapshot harga jual SO miliknya |
| Data seed bocor ke produksi | Project demo exact, host loopback, preflight dua emulator, redirect error, app emulator debug-only |

Tidak ada perubahan Rules yang diperlukan hanya untuk label CRUD. Rules existing
dipertahankan; tidak membuka akses pelanggan/teknisi ke data internal.

## Batas dan temuan

1. Admin dipercaya mengesahkan snapshot partSubtotal/parts saat issue invoice.
   Rules tidak melakukan fold ledger dinamis; admin dengan client modifikasi
   dapat menyimpang pada penerbitan. Risiko existing terdokumentasi di
   PAYMENT_SCHEMA.md, bukan jaminan anti-fraud admin. Rekonsiliasi operator wajib.
2. IAM/Console/Admin SDK melewati Rules. Operator harus membatasi akses proyek;
   scope QA ini tidak memeriksa IAM atau kredensial production.
3. users.role/active hanya operator tepercaya, termasuk untuk admin aplikasi.
   Ini kontrol sengaja, bukan bug CRUD. Arsip direktori teknisi tidak otomatis
   menonaktifkan akun Auth. Lihat matriks kemampuan pada laporan.
4. Firestore Emulator tidak membuktikan indexes production tersedia. Check 35
   definisi statis perlu dilanjutkan dengan READY dan smoke query setelah deploy.
5. Tidak ada scanner dependency/SAST eksternal yang diklaim dijalankan. Warning
   dependency tooling dilaporkan sesuai log; tidak mengubah versi massal tanpa
   investigasi. Data catatan kerja terbaca customer pemilik: jangan isi rahasia.
6. Node test integration menggunakan bypass Rules hanya untuk users/manifest dan
   cleanup. Operasi domain seed dijalankan dengan login role sebenarnya.
7. Disable akun Auth menolak login/refresh berikutnya; token yang sudah terbit
   tidak dijamin langsung hilang. Untuk memutus akses Firestore segera, operator
   juga menetapkan users.active=false. Test deactivation existing menguji
   penolakan akses dengan sesi yang sebelumnya aktif.

## Checklist operator yang masih diperlukan

- [ ] Review Rules/indexes bersama dan hak IAM operator production.
- [ ] Verifikasi Email/Password enabled, provider lain/billing tetap sesuai scope.
- [ ] Provision akun operasional admin/teknisi melalui operator tepercaya.
- [ ] Approve deploy production secara terpisah jika diperlukan.
- [ ] Jalankan perintah berikut hanya setelah persetujuan eksplisit.
- [ ] Tunggu semua index READY; smoke query filter/pagination tiga role memakai
  data operasional valid dan tanpa data dummy otomatis.
- [ ] Uji verifikasi/reset email production secara manual dengan akun berizin.

```sh
firebase deploy --only firestore:rules,firestore:indexes --project bengkelku-app-bebd9
```

Status sesi ini: **NOT DEPLOYED**. CI tidak punya deploy atau secrets.
