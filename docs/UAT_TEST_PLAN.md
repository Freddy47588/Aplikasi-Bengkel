# Template UAT BengkelKu

Status pelaksanaan: **NOT RUN**. Tidak ada responden, hasil penilaian, tanda
tangan atau persetujuan yang diisi otomatis. Template ini terpisah dari hasil.

Versi/commit: ______; tanggal WIB: ______; fasilitator: ______; lokasi: ______.
Perangkat/OS/font/koneksi: ______; dataset emulator/run ID: ______.
Kode responden: ______; peran: pelanggan / admin-pemilik / teknisi / dosen.
Nama dan tanda tangan bersifat opsional sesuai prosedur penelitian dan izin.
Jangan mengumpulkan password, nomor rekening, atau data pribadi tidak perlu.

## Instruksi penguji

1. Fasilitator menjalankan emulator/seed sesuai TEST_DATA_GUIDE dan memberikan
   akun role yang benar secara lokal; jelaskan bahwa data merupakan simulasi.
2. Penguji mengerjakan tugas dengan bahasa sendiri, tanpa diarahkan ke jawaban.
3. Catat waktu mulai/selesai, hambatan, hasil aktual dan bukti perangkat asli.
4. Nilai kuesioner setelah tugas. Boleh berhenti atau melewati tugas dengan alasan.
5. Fasilitator menghapus kredensial/bukti sensitif; reset setelah sesi selesai.

| ID | Role | Skenario | Kriteria diterima | Actual / status / bukti |
| --- | --- | --- | --- | --- |
| UAT-C1 | Pelanggan | Login; tambah/edit/arsip kendaraan | Data milik sendiri, validasi jelas | Belum diisi / NOT RUN / — |
| UAT-C2 | Pelanggan | Booking dan cancel booking lain | Jadwal dan status benar, slot tidak ganda | Belum diisi / NOT RUN / — |
| UAT-C3 | Pelanggan | Lihat tracking, riwayat, invoice/PDF | Informasi servis/biaya dapat dipahami | Belum diisi / NOT RUN / — |
| UAT-A1 | Admin | Confirm booking, buat SO, assign teknisi | Tugas benar, lock kapasitas satu | Belum diisi / NOT RUN / — |
| UAT-A2 | Admin | Kelola sparepart/receipt/approve request | Stok dan ledger benar | Belum diisi / NOT RUN / — |
| UAT-A3 | Admin | Review complete, invoice, partial/paid, PDF/laporan | Total, audit, omzet dan sisa benar | Belum diisi / NOT RUN / — |
| UAT-T1 | Teknisi | Buka tugas sendiri, checklist/diagnosis/tindakan | Input tersimpan dan mudah ditemukan | Belum diisi / NOT RUN / — |
| UAT-T2 | Teknisi | Request part, lanjutkan, ajukan selesai | Status sesuai proses; admin review akhir | Belum diisi / NOT RUN / — |
| UAT-R1 | Semua | Background/foreground, logout/login, jaringan putus | Error jelas, data/sesi tidak tertukar | Belum diisi / NOT RUN / — |

Status yang tersedia: PASS, FAIL, BLOCKED, NOT RUN. PASS hanya jika observed
result memenuhi expected result dan bukti dicatat. Task yang belum ada UI-nya
ditandai BLOCKED dengan referensi bug, bukan dibantu melalui Console lalu PASS.

## Form temuan dan komentar

Bug ID: ______; UAT ID: ______; role: ______; build/perangkat: ______.
Prasyarat/input: ______; langkah reproduksi: ______; harapan: ______.
Actual: ______; frekuensi: ______; dampak/severity: ______; bukti: ______.
Komentar bebas dan saran: ____________________________________________.
Fasilitator memindahkan bug terverifikasi ke BUG_TRACKER tanpa identitas pribadi.

## Ringkasan penerimaan (diisi setelah pelaksanaan)

Jumlah responden aktual per role: ______. Task PASS/FAIL/BLOCKED/NOT RUN: ______.
Skor per pertanyaan dan jumlah jawaban valid: ______. Temuan belum selesai: ______.
Keputusan: diterima / diterima bersyarat / belum diterima. Alasan: ______.
Perbaikan dan uji ulang yang diperlukan: ______; tanggal target: ______.
Penguji/pemilik (opsional): ______; fasilitator: ______; tanggal: ______.
Tanda tangan/persetujuan (sesuai prosedur penelitian): __________________.

Tidak menyimpulkan diterima dari rata-rata Likert saja. Semua task kritis harus
berhasil; bug kritis harus ditutup dan diuji ulang. Kriteria penelitian tambahan
disepakati dosen/pemilik sebelum sesi, bukan dipilih sesudah melihat hasil.
