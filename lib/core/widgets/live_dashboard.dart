import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/widgets/empty_state.dart';
import 'package:bengkel_kendaraan/core/widgets/foundation_pages.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/status_chip.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:bengkel_kendaraan/features/auth/data/auth_repository.dart';
import 'package:bengkel_kendaraan/features/customer/presentation/customer_dashboard_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technician_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LiveDashboard extends ConsumerWidget {
  const LiveDashboard({
    super.key,
    this.customer = true,
    this.technician = false,
  });

  final bool customer;
  final bool technician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final role = session.role;
    if (role == null) return const LoadingState();
    if (role.name == 'technician' || (!customer && technician)) {
      return const TechnicianOverview();
    }
    if (role.name == 'customer' || (customer && !technician)) {
      return const CustomerDashboardScreen();
    }

    final ordersAsync = ref.watch(ordersPageProvider(null));
    final bookingsAsync = ref.watch(bookingsProvider);
    final lowStockAsync = ref.watch(
      inventoryPageProvider((
        cursor: null,
        search: '',
        category: '',
        active: true,
        lowOnly: true,
      )),
    );

    final orders = ordersAsync.asData?.value.items ?? const <ServiceOrder>[];
    final bookings = bookingsAsync.asData?.value ?? const <Booking>[];
    final lowParts = lowStockAsync.asData?.value.items ?? const [];

    final awaitingApproval = orders
        .where((o) => o.status == ServiceOrderStatus.awaitingApproval)
        .toList();
    final activeOrders = orders.where((o) => !o.status.terminal).toList();
    final pendingBookings = bookings
        .where((b) => b.status == BookingStatus.pending)
        .toList();

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
                'BengkelKu Admin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(ordersPageProvider(null));
              ref.invalidate(bookingsProvider);
              ref.invalidate(inventoryPageProvider);
            },
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go('/admin/profile'),
          ),
        ],
      ),
      bottomNavigationBar: const MobileNavigation(role: 'admin'),
      body: WorkshopBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'Halo, Admin Bengkel',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau antrean booking, penugasan teknisi, persetujuan servis, dan stok sparepart.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            CarbonSpotlightCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'RINGKASAN OPERASIONAL',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          constraints.maxWidth < 260 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.3;
                      final cards = [
                        _CarbonKpi(
                          label: 'SO Aktif',
                          value: '${activeOrders.length}',
                          highlight: true,
                        ),
                        _CarbonKpi(
                          label: 'Booking Pending',
                          value: '${pendingBookings.length}',
                        ),
                        _CarbonKpi(
                          label: 'Persetujuan',
                          value: '${awaitingApproval.length}',
                        ),
                        _CarbonKpi(
                          label: 'Stok Menipis',
                          value: '${lowParts.length}',
                        ),
                      ];
                      if (stacked) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final card in cards)
                              SizedBox(
                                width: constraints.maxWidth,
                                child: card,
                              ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 10),
                              Expanded(child: cards[1]),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: cards[2]),
                              const SizedBox(width: 10),
                              Expanded(child: cards[3]),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.go('/admin/orders'),
                        icon: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('Kelola Service Order'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        onPressed: () => context.go('/admin/invoices'),
                        child: const Text('Kasir & Laporan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (awaitingApproval.isNotEmpty) ...[
              const SizedBox(height: 16),
              Material(
                color: AppColors.accentSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.accentBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${awaitingApproval.length} Servis Menunggu Persetujuan Admin',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Periksa checklist teknisi, diagnosis, dan catatan pemakaian part sebelum menyelesaikan order.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final o in awaitingApproval.take(2))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UniversalVehicleThumb(
                            vehicleName: o.text('vehicleName'),
                            size: 40,
                          ),
                          title: Text(
                            '${o.text('vehiclePlate')} · ${o.text('vehicleName')}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(o.text('serviceName')),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go('/admin/orders/${o.id}'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _AdminHeading(
              title: 'Booking Masuk',
              actionLabel: 'Semua Booking',
              onTap: () => context.go('/admin/bookings'),
            ),
            const SizedBox(height: 8),
            bookingsAsync.when(
              loading: () => const LoadingState(),
              error: (_, _) =>
                  LoadError(onRetry: () => ref.invalidate(bookingsProvider)),
              data: (items) {
                final queue = items.take(3).toList();
                if (queue.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada booking masuk',
                    description:
                        'Permintaan booking pelanggan akan tampil di sini.',
                    icon: Icons.event_note_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final b in queue)
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
                            onTap: () => context.go('/admin/bookings/${b.id}'),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  UniversalVehicleThumb(
                                    vehicleName: b.vehicle.name,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.vehicle.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${b.draft.service} • ${bookingSchedule(b.draft.scheduledAt)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.muted,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            IndonesianPlateBadge(
                                              plate: b.vehicle.plate,
                                            ),
                                            StatusChip(
                                              label: b.status.label,
                                              tone:
                                                  b.status ==
                                                      BookingStatus.confirmed
                                                  ? StatusChipTone.success
                                                  : b.status ==
                                                        BookingStatus.pending
                                                  ? StatusChipTone.warning
                                                  : StatusChipTone.neutral,
                                            ),
                                          ],
                                        ),
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
                );
              },
            ),
            const SizedBox(height: 16),
            _AdminHeading(
              title: 'Perhatian Stok Sparepart',
              actionLabel: 'Buka Inventori',
              onTap: () => context.go('/admin/inventory'),
            ),
            const SizedBox(height: 8),
            lowStockAsync.when(
              loading: () => const LoadingState(),
              error: (_, _) => LoadError(
                onRetry: () => ref.invalidate(inventoryPageProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Semua sparepart aktif berada di atas batas minimum.',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final part in page.items.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              part.text('name'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'SKU ${part.text('sku')} • Sisa ${part.stock} ${part.text('unit')}',
                            ),
                            trailing: StatusChip(
                              label: part.stock == 0 ? 'Habis' : 'Minimum',
                              tone: part.stock == 0
                                  ? StatusChipTone.danger
                                  : StatusChipTone.warning,
                            ),
                            onTap: () => context.go('/admin/inventory'),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CarbonKpi extends StatelessWidget {
  const _CarbonKpi({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondary.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? AppColors.secondary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminHeading extends StatelessWidget {
  const _AdminHeading({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

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
              TextButton(onPressed: onTap, child: Text(actionLabel)),
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
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        );
      },
    );
  }
}
