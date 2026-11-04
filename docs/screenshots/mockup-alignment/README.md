# Render fixture Flutter

36 gambar `fixture-alignment-*.png` dirender dari widget aplikasi pada
390x740dp (PNG 780x1480), dengan font SDK dan data fixture. Semua diperiksa
secara visual pada 4 November 2026. Tidak ada data pelanggan production.

Contoh:

- [Splash](fixture-alignment-splash.png)
- [Login](fixture-alignment-login.png)
- [Register](fixture-alignment-register.png)
- [Verifikasi](fixture-alignment-verification.png)
- [Dashboard pelanggan](fixture-alignment-customer-home.png)
- [Kendaraan](fixture-alignment-customer-vehicles.png)
- [Booking](fixture-alignment-customer-booking.png)
- [Admin](fixture-alignment-admin-home.png)
- [Teknisi](fixture-alignment-technician-home.png)
- [Checklist](fixture-alignment-checklist.png)
- [Inventory](fixture-alignment-admin-inventory.png)
- [Detail stok](fixture-alignment-part-detail.png)
- [Riwayat](fixture-alignment-customer-history-completed.png)
- [Invoice](fixture-alignment-admin-invoices-completed.png)

Gambar menangkap viewport bagian atas; konten di bawah dapat di-scroll.
Ring hitam pada tombol tambah kendaraan adalah indikator fokus keyboard
Flutter yang ikut terekam pada fixture. Tes terpisah menelusuri seluruh
konten pada 320dp dan pembesaran teks 200%.

Ini bukti render widget, bukan UAT pada perangkat asli. Cara regenerasi dan
hasil pengujian ada pada [laporan](../../MOCKUP_ALIGNMENT_REPORT.md).
