import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/data/service_history_repository.dart';
import 'package:bengkel_kendaraan/core/data/vehicle_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/models/service_history.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/widgets/foundation_pages.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/status_chip.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersPageProvider(null));
    final bookingsAsync = ref.watch(bookingsProvider);
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final historyAsync = ref.watch(historyPageProvider(const HistoryFilter()));

    final orders = ordersAsync.asData?.value.items ?? const <ServiceOrder>[];
    final bookings = bookingsAsync.asData?.value ?? const <Booking>[];
    final vehicles = (vehiclesAsync.asData?.value ?? const <Vehicle>[])
        .where((v) => v.active)
        .toList();
    final history = historyAsync.asData?.value.items ?? const <ServiceOrder>[];

    final activeOrders = orders.where((o) => !o.status.terminal).toList();
    final activeBookings = bookings.where((b) => b.status.isActive).toList();
    final leadOrder = activeOrders.isNotEmpty ? activeOrders.first : null;
    final leadBooking = leadOrder == null && activeBookings.isNotEmpty
        ? activeBookings.first
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Row(
          children: [
            BrandEmblem(size: 32),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'BengkelKu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Booking Servis',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.go('/customer/booking'),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go('/customer/profile'),
          ),
        ],
      ),
      bottomNavigationBar: const MobileNavigation(role: 'customer'),
      body: WorkshopBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'Halo, Pelanggan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau servis aktif, kelola garasi, dan pesan jadwal kunjungan bengkel.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _CustomerSpotlight(
              order: leadOrder,
              booking: leadBooking,
              onOpenOrder: (id) => context.go('/customer/orders/$id'),
              onOpenBooking: (id) => context.go('/customer/bookings/$id'),
              onCreateBooking: () => context.go('/customer/booking'),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked =
                    constraints.maxWidth < 340 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                if (stacked) {
                  final halfW = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: halfW,
                        child: _CustomerStatTile(
                          label: 'Booking Aktif',
                          value: '${activeBookings.length}',
                          accent: true,
                          onTap: () => context.go('/customer/bookings'),
                        ),
                      ),
                      SizedBox(
                        width: halfW,
                        child: _CustomerStatTile(
                          label: 'Garasi',
                          value: '${vehicles.length}',
                          onTap: () => context.go('/customer/vehicles'),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _CustomerStatTile(
                          label: 'Riwayat',
                          value: '${history.length}',
                          onTap: () => context.go('/customer/history'),
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _CustomerStatTile(
                        label: 'Booking Aktif',
                        value: '${activeBookings.length}',
                        accent: true,
                        onTap: () => context.go('/customer/bookings'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CustomerStatTile(
                        label: 'Garasi',
                        value: '${vehicles.length}',
                        onTap: () => context.go('/customer/vehicles'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CustomerStatTile(
                        label: 'Riwayat',
                        value: '${history.length}',
                        onTap: () => context.go('/customer/history'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Layanan Cepat',
              actionLabel: 'Booking',
              onAction: () => context.go('/customer/booking'),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 4 : 2;
                final spacing = 10.0;
                final itemWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                const items = [
                  (QuickServiceKind.periodic, 'Servis Berkala'),
                  (QuickServiceKind.oil, 'Ganti Oli'),
                  (QuickServiceKind.brake, 'Rem & Kaki'),
                  (QuickServiceKind.electric, 'Cek Kelistrikan'),
                ];
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final entry in items)
                      SizedBox(
                        width: itemWidth,
                        child: _QuickCategoryCard(
                          kind: entry.$1,
                          label: entry.$2,
                          onTap: () => context.go('/customer/booking'),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            _SectionHeading(
              title: 'Garasi Saya',
              actionLabel: 'Kelola',
              onAction: () => context.go('/customer/vehicles'),
            ),
            const SizedBox(height: 10),
            if (vehiclesAsync.isLoading && vehicles.isEmpty)
              const LoadingState()
            else if (vehicles.isEmpty)
              _EmptyCard(
                title: 'Belum ada kendaraan terdaftar',
                subtitle:
                    'Tambahkan motor atau mobil Anda agar pengisian booking lebih cepat.',
                cta: 'Tambah kendaraan',
                onTap: () => context.go('/customer/vehicles'),
              )
            else
              Column(
                children: [
                  for (final v in vehicles.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.go('/customer/vehicles'),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                UniversalVehicleThumb(
                                  kind: v.kind?.name,
                                  vehicleName: v.name,
                                  size: 48,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      IndonesianPlateBadge(plate: v.plate),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            _SectionHeading(
              title: 'Aktivitas Terbaru',
              actionLabel: 'Semua Riwayat',
              onAction: () => context.go('/customer/history'),
            ),
            const SizedBox(height: 10),
            if (bookings.isEmpty && history.isEmpty)
              _EmptyCard(
                title: 'Belum ada aktivitas servis',
                subtitle:
                    'Riwayat booking, progres pengerjaan, dan invoice akan tampil di sini.',
                cta: 'Booking Servis',
                onTap: () => context.go('/customer/booking'),
              )
            else ...[
              for (final b in bookings.take(2))
                _ActivityCard(
                  vehicleName: b.vehicle.name,
                  plate: b.vehicle.plate,
                  subtitle:
                      '${b.draft.service} • ${bookingSchedule(b.draft.scheduledAt)}',
                  status: StatusChip(
                    label: b.status.label,
                    tone: b.status == BookingStatus.confirmed
                        ? StatusChipTone.success
                        : b.status == BookingStatus.pending
                        ? StatusChipTone.warning
                        : StatusChipTone.neutral,
                  ),
                  onTap: () => context.go('/customer/bookings/${b.id}'),
                ),
              for (final order in history.take(2))
                _ActivityCard(
                  vehicleName: order.text('vehicleName'),
                  plate: order.text('vehiclePlate'),
                  subtitle:
                      '${order.text('serviceName')} • Selesai ${historyDate(order.date('completedAt'))}',
                  status: const StatusChip(
                    label: 'Selesai',
                    tone: StatusChipTone.success,
                  ),
                  onTap: () => context.go('/customer/history/${order.id}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerSpotlight extends StatelessWidget {
  const _CustomerSpotlight({
    required this.order,
    required this.booking,
    required this.onOpenOrder,
    required this.onOpenBooking,
    required this.onCreateBooking,
  });

  final ServiceOrder? order;
  final Booking? booking;
  final void Function(String id) onOpenOrder;
  final void Function(String id) onOpenBooking;
  final VoidCallback onCreateBooking;

  int _orderStep(ServiceOrderStatus status) => switch (status) {
    ServiceOrderStatus.queued || ServiceOrderStatus.assigned => 0,
    ServiceOrderStatus.inProgress ||
    ServiceOrderStatus.paused ||
    ServiceOrderStatus.awaitingApproval => 1,
    ServiceOrderStatus.completed || ServiceOrderStatus.cancelled => 2,
  };

  @override
  Widget build(BuildContext context) {
    if (order != null) {
      final current = order!;
      return CarbonSpotlightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UniversalVehicleThumb(
                  vehicleName: current.text('vehicleName'),
                  size: 52,
                  darkSurface: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SERVIS BERJALAN',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.text('vehicleName'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.text('serviceName'),
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IndonesianPlateBadge(
                  plate: current.text('vehiclePlate'),
                  dark: true,
                ),
                StatusChip(
                  label: current.status.label,
                  tone: StatusChipTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ServiceProgressStrip(
              activeStep: _orderStep(current.status),
              labels: const ['Diterima', 'Dikerjakan', 'Selesai'],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onOpenOrder(current.id),
              child: const Text('Pantau Progres'),
            ),
          ],
        ),
      );
    }

    if (booking != null) {
      final current = booking!;
      return CarbonSpotlightCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                UniversalVehicleThumb(
                  vehicleName: current.vehicle.name,
                  size: 50,
                  darkSurface: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BOOKING TERJADWAL',
                        style: TextStyle(
                          color: AppColors.accentLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.vehicle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        bookingSchedule(current.draft.scheduledAt),
                        style: const TextStyle(
                          color: Color(0xFFD1D5DB),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                IndonesianPlateBadge(plate: current.vehicle.plate, dark: true),
                StatusChip(
                  label: current.status.label,
                  tone: current.status == BookingStatus.confirmed
                      ? StatusChipTone.success
                      : StatusChipTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const ServiceProgressStrip(
              activeStep: 0,
              labels: ['Booking', 'Diproses', 'Selesai'],
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onOpenBooking(current.id),
              child: const Text('Lihat Detail Booking'),
            ),
          ],
        ),
      );
    }

    return CarbonSpotlightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const UniversalVehicleThumb(size: 52, darkSurface: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SIAP SERVIS HARI INI?',
                      style: TextStyle(
                        color: AppColors.accentLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Booking Servis Tanpa Antre',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pilih slot jam kunjungan 09:00–16:00 WIB langsung dari aplikasi.',
                      style: TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreateBooking,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: const Text('Booking Servis'),
          ),
        ],
      ),
    );
  }
}

class _CustomerStatTile extends StatelessWidget {
  const _CustomerStatTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.accentSoft : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent ? AppColors.accentBorder : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: accent ? AppColors.secondary : AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (narrow) {
          return Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        );
      },
    );
  }
}

class _QuickCategoryCard extends StatelessWidget {
  const _QuickCategoryCard({
    required this.kind,
    required this.label,
    required this.onTap,
  });

  final QuickServiceKind kind;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuickServiceIcon(kind),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.vehicleName,
    required this.plate,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  final String vehicleName;
  final String plate;
  final String subtitle;
  final Widget status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UniversalVehicleThumb(vehicleName: vehicleName, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicleName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IndonesianPlateBadge(plate: plate),
                    status,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
