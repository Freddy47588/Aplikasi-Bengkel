# BengkelKu — design system

Phase 06.5, 2 November 2026 (Asia/Jakarta). Tema Material 3 terang, identitas
Steel Navy & Royal Blue. Tidak ada dark mode parsial.

## Token warna

| Token | Hex | Penggunaan |
| --- | --- | --- |
| primary | `#1E3A5F` | Steel Navy, judul, hero, header PDF |
| secondary | `#2563EB` | Royal Blue, tombol utama, emblem, progres, tab terpilih |
| accent | `#F59E0B` | Amber, teks aksen pada navy |
| background | `#F8FAFC` | Off-white, latar halaman |
| muted | `#64748B` | Slate Gray, teks sekunder |
| onMuted | `#475569` | Teks status netral pada latar tint |
| surface | `#FFFFFF` | Kartu dan input |
| border | `#E2E8F0` | Garis pemisah dan kartu |
| success | `#166534` | Selesai, lunas, akun aktif |
| info | `#1D4ED8` | Informasi/progres |
| warning | `#854D0E` | Menunggu, stok rendah, belum lunas |
| danger | `#B91C1C` | Kesalahan dan status berbahaya |

Amber hanya untuk aksen di atas navy, bukan teks kecil di atas putih. Tombol utama Royal Blue
dengan teks putih. Status memakai teks gelap dan latar tint 12%, serta label
teks agar makna tidak hanya bergantung warna.

## Tata letak dan tipografi

`lib/app/theme/app_tokens.dart`: spacing 4/8/12/16/24/32dp, radius kontrol 12,
kartu 20, hero 24, lebar konten maksimal 960dp. Kartu tanpa elevasi, AppBar
tanpa shadow saat scroll. Tipografi Roboto/platform fallback tanpa font jaringan:
headline untuk sapaan/angka, title untuk bagian, body untuk informasi dan
label untuk status/tindakan. Tidak mengunci tinggi teks atau kartu statistik.

`AdaptiveCards` menyusun 1–3 kolom berdasarkan lebar tersedia, tanpa aspect
ratio tetap. `WorkshopBody` menyediakan SafeArea dan batas lebar pada form,
detail, daftar, dan transaksi. Form menggunakan scroll dan dismiss keyboard
saat drag. Tombol utama minimal 52dp, outlined/text/icon minimal 48dp; input
helper/error membungkus hingga 4 baris. Dialog konfirmasi dapat di-scroll.

## Komponen bersama

| Komponen | Peran |
| --- | --- |
| `BrandEmblem`, `BrandLockup` | Asset emblem asli dan identitas login ringkas |
| `WorkshopHero` | Sapaan ringkas per role; aksi utama dashboard langsung di bawahnya |
| `AdaptiveCards` | Grid responsif dengan tinggi alami |
| `DashboardStatCard` | Angka dari provider, label batas data |
| `QuickActionCard` | Ikon, label, panah, seluruh kartu dapat ditekan |
| `ContentSection`, `SectionHeader` | Hierarki bagian dan rincian biaya |
| `StatusChip`, `PaymentBadge` | Status semantik berlabel |
| `LoadingState`, `LoadError`, `RetryLoad` | Loading dan error dengan retry |
| `EmptyState` | Penjelasan ketika data kosong |
| `ServiceTimeline` | Tahapan servis dari status sebenarnya |
| `HistoryPaymentSummary` | Status invoice realtime, peringatan cache |
| `MobileNavigation`, `WorkspaceLinks` | Navigasi sesuai area route dan role |

## Area navigasi

Customer: Beranda, Booking (form/daftar/detail), Servis (progres/riwayat/invoice),
Profil (akun/kendaraan). Admin: Beranda, Booking, Bengkel (tim, order, inventory,
invoice/laporan, riwayat), Profil. Teknisi: Beranda, Pekerjaan (jobs/order),
Riwayat, Profil. Halaman transaksi memiliki navigasi bawah yang konsisten.
Tautan pada area Bengkel/Servis menjelaskan kelompok layar tersebut.

## Data dan aksesibilitas

Dashboard memakai provider Firebase existing. Booking dibatasi 100, order 20,
kendaraan 50, inventory per halaman. Angka order secara eksplisit diberi label
"pada halaman ini"; dashboard tidak mengarang omzet atau menjumlahkan halaman
parsial. Omzet hanya muncul setelah laporan existing dimuat dengan periode
yang dipilih. Teknisi tidak membaca invoice dan tidak mendapat tombol admin.

Widget tests memakai skala teks 1,3× dan lebar 320/360/390/430/800dp; pengujian
regresi mencakup tablet 1280dp. Lihat laporan fase untuk hasil aktual dan batas
pengujian perangkat/platform. Status offline hanya ditampilkan bila metadata
cache tersedia; kegagalan jaringan tidak diklaim sebagai data kosong.

Kontras warna utama (rasio luminans sRGB): navy/putih 11,50:1,
putih/Royal Blue 5,17:1, Slate Gray/Off-white 4,55:1, dan Amber/navy 5,36:1.
Amber tidak digunakan sebagai teks kecil pada latar putih.

Pilihan jenis servis menggabungkan katalog aktif dan snapshot pada halaman
riwayat yang dimuat, sehingga jenis servis nonaktif tetap dapat difilter.
Pilihan yang sedang dipakai dipertahankan saat data halaman berubah.
