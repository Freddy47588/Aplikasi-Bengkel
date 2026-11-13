# Matriks fungsi audit 12-13 November 2026

Base `828fc59`; lingkungan otomatis Flutter fake/mock dan Firebase Emulator.
PASS di bawah berarti cakupan otomatis tertera, bukan black-box perangkat atau
UAT. Semua pengujian native sesi ini NOT RUN. Hasil run final pada
[REGRESSION_RESULTS](REGRESSION_RESULTS.md).

| Role / TA | Fitur / route | Provider / repository / koleksi | Status awal | Bug | Perbaikan | Tes | Status akhir otomatis |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Semua / F-01 | Login/register/reset `/login` | authSession / FirebaseAuthRepository / Auth, users | NOT RUN | Tidak teridentifikasi | Tidak diubah | auth_session, firebase_widgets, account_refinement; Auth emulator | PASS |
| Semua / F-01 | Verifikasi/inactive/refresh `/account` | authSession / users | NOT RUN | Tidak teridentifikasi | Tidak diubah | auth_session, session_splash, account_refinement, firestore rules | PASS |
| Semua / F-01 | Profil/logout `/:role/profile` | authSession / Auth | NOT RUN | Tidak teridentifikasi | Tidak diubah | account_refinement, ui_ux_polish, session redirect | PASS |
| Pelanggan / F-02 | Tambah/edit/archive `/customer/vehicles` | vehicles, allVehicles / VehicleRepository / vehicles | FAIL tes tap | QA-17 | Langkah reveal pada test lokal; lint lokal | firebase_repositories/widgets, customer_mockup; rules ownership/archive | PASS working tree, perubahan lokal tidak dipublish |
| Admin / F-02 | CRUD kendaraan pelanggan | Tidak ada route/modul admin vehicles | BLOCKED | Gap TA | Rekomendasi otorisasi terpisah | Inspeksi router/repository/rules | BLOCKED |
| Pelanggan / F-03 | Katalog/dropdown `/customer/booking` | services / FirestoreServiceRepository / services | FAIL race | QA-14, QA-13 | Snapshot siap, validasi pilihan, submit disabled saat katalog belum siap/kosong | booking_catalog_regression, booking_review_layout | PASS otomatis; QA-13 native NOT RUN |
| Pelanggan / F-03 | Review/submit booking | vehicles, services, bookingRepository / bookings, bookingSlots | FAIL dialog ganda | QA-15 | Lock sejak review dan guard panggilan berulang | booking_catalog_regression, mobile_foundation, firestore race | PASS |
| Pelanggan / F-03 | Daftar/detail/cancel `/customer/bookings/:id` | bookings, serviceOrder / bookings, bookingSlots | NOT RUN | Tidak teridentifikasi | Tidak diubah | mobile_foundation, firebase_repositories/widgets, service_orders rules | PASS |
| Admin / F-03 | Tinjau/confirm/reject `/admin/bookings/:id` | bookings / FirestoreBookingRepository | NOT RUN | Tidak teridentifikasi | Tidak diubah | mobile_foundation, booking repository, rules | PASS |
| Admin / F-04 | SO/create/assign/reassign `/admin/orders/:id` | ordersPage, serviceOrder / ServiceOrderRepository / serviceOrders, technicians, events | NOT RUN | Tidak teridentifikasi | Tidak diubah | service_order repository/widgets, admin_service_refinement, rules race | PASS |
| Teknisi / F-04 | Tugas `/technician/jobs`, `/technician/orders/:id` | ordersPage/serviceOrder scoped UID | NOT RUN | Tidak teridentifikasi | Tidak diubah | technician_refinement, service_order_widgets, rules isolation | PASS |
| Teknisi / F-04 | Checklist/diagnosis/tindakan/start/pause/resume | ServiceOrderRepository / serviceOrders, events | NOT RUN | Tidak teridentifikasi | Tidak diubah | technician_forms_refinement, service_order_repository, integration | PASS |
| Teknisi + admin / F-04 | Ajukan selesai/review/revisi/complete | serviceOrder / updateWork / events, lock teknisi | NOT RUN | Tidak teridentifikasi | Tidak melewati review admin | service_order widgets/repository/rules | PASS |
| Admin / F-05 | Direktori teknisi `/admin/technicians` | techniciansPage / watch/saveTechnician / technicians, trusted users | NOT RUN | Batas provisioning | Tidak diubah | admin_service_refinement, service_order repository/rules | PASS; CRUD role Auth ACCEPTED LIMITATION |
| Admin / F-05 | Master sparepart `/admin/inventory` | inventoryPage/sparepart / InventoryRepository / spareparts | NOT RUN | Tidak teridentifikasi | Tidak diubah | inventory repository/widgets/refinement/rules | PASS |
| Admin / F-06 | Receipt/koreksi/usage/reversal/ledger | ledgerPage / post, reverse / stockMovements, partUsages | NOT RUN | Tidak teridentifikasi | Tidak diubah | inventory tests, race/reversal/negative-stock emulator | PASS |
| Teknisi + admin / F-06 | Request/approval sparepart, sublayar SO | orderInventory / requestPart, decideRequest / partRequests | NOT RUN | Tidak teridentifikasi | Tidak diubah | technician_forms_refinement, inventory rules, phase07 integration | PASS |
| Semua / F-07 | Tracking/riwayat/filter `/:role/orders`, `/:role/history/:id` | historyPage/historyParts/serviceOrder / serviceOrders, events, partUsages | NOT RUN | Tidak teridentifikasi | Tidak diubah | service_history repository/widgets, live invoice tests | PASS |
| Admin + pelanggan / F-08 | Invoice/detail `/:role/invoices/:id` | invoicePage/invoice / PaymentRepository / invoices | NOT RUN | Tidak teridentifikasi | Tidak diubah | payment repository/widgets, invoice isolation rules | PASS |
| Admin / F-08 | Partial/paid/void/refund | record / invoices, payments | NOT RUN | Batas kepercayaan snapshot admin | Tidak diubah | payment tamper/replay/overpay/concurrent tests | PASS; QA-04 ACCEPTED LIMITATION |
| Admin + pelanggan / F-08 | PDF/cetak/bagikan | buildInvoicePdf / printing native | NOT RUN | Tidak ada perangkat | Tidak diubah | PDF generation unit test; native NOT RUN | PASS PDF bytes; NOT RUN native |
| Admin / F-09 | Laporan periode `/admin/invoices` | reportRepository / bookings, SO, invoices, movements, spareparts | FAIL batas waktu | QA-16 | Bandingkan durasi tanpa pembulatan | report_period_regression, payment_repository, integration revenue | PASS |
| Semua | Dashboard `/:role/home` | booking/order/history/inventory scoped providers | FAIL tes tap ringkasan | QA-17 | Reveal sebelum tap; assertion hitungan tetap | ui_ux_polish, visual_fidelity, audit_text_scaling | PASS otomatis |
| Admin | CRUD katalog layanan | Rules services tersedia; UI tidak ada | ACCEPTED LIMITATION | QA-01 | Tidak membangun modul baru | Inspeksi source dan dokumen keputusan scope | ACCEPTED LIMITATION |
| Semua | Notifikasi | Tidak ada route/provider/koleksi | NOT RUN | Belum diimplementasikan | Tidak membangun push/FCM | Inventaris source | NOT RUN, fitur belum ada |

Pemetaan route di atas juga mencakup modal/sublayar Navigator yang tidak memiliki
deep link tersendiri. UI tidak menawarkan penghapusan ledger, promosi role atau
perubahan riwayat terminal. Test mock tidak membuktikan rules; tabel menyebut
suite emulator terpisah untuk otorisasi dan integritas data.
