import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/data/booking_repository.dart';
import '../../../core/data/service_history_repository.dart';
import '../../../core/data/vehicle_repository.dart';
import '../../../core/models/service_history.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/foundation_pages.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../auth/data/auth_repository.dart';
import '../../technician/presentation/service_orders_screen.dart';
import 'customer_vehicle_art.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated || session.role?.name != 'customer') {
      return const SizedBox.shrink();
    }
    final orders = ref.watch(ordersPageProvider(null));
    final bookings = ref.watch(bookingsProvider);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final summary = Card(
      shape: _shape,
      child: InkWell(
        onTap: () => context.go('/customer/orders'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.secondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ringkasan Servis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              orders.when(
                loading: () => const LoadingState(),
                error: (_, _) => LoadError(
                  onRetry: () => ref.invalidate(ordersPageProvider(null)),
                ),
                data: (page) {
                  final own = page.items
                      .where((o) => o.text('customerId') == session.userId)
                      .toList();
                  final metrics = [
                    _CustomerMetric(
                      value: '${own.where((o) => !o.status.terminal).length}',
                      label: 'Servis aktif',
                    ),
                    _CustomerMetric(
                      value:
                          '${own.where((o) => o.status == ServiceOrderStatus.completed).length}',
                      label: 'Servis selesai',
                    ),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (largeText)
                        ...metrics
                      else
                        Row(
                          children: [
                            for (final metric in metrics)
                              Expanded(child: metric),
                          ],
                        ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dari maksimal 20 Service Order terbaru Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      bottomNavigationBar: const MobileNavigation(role: 'customer'),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Selamat Datang,'),
                      const SizedBox(height: 4),
                      Text(
                        session.email ?? 'Akun Pelanggan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                const LogoutButton(icon: true),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Booking, kendaraan, dan riwayat servis Anda.'),
            if (!largeText) const CustomerVehicleArt(height: 112),
            summary,
            const SizedBox(height: 20),
            const SectionHeader(title: 'Akses Cepat'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, box) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final action in const [
                    (
                      'Buat Booking',
                      Icons.calendar_month_outlined,
                      '/customer/booking',
                    ),
                    (
                      'Kendaraan Saya',
                      Icons.directions_car_outlined,
                      '/customer/vehicles',
                    ),
                    ('Riwayat Servis', Icons.history, '/customer/history'),
                  ])
                    SizedBox(
                      width: largeText ? box.maxWidth : (box.maxWidth - 16) / 3,
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: _shape,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.go(action.$3),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  action.$2,
                                  size: 30,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  action.$1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Servis / Booking Aktif',
              actionLabel: 'Lihat semua',
              onPressed: () => context.go('/customer/orders'),
            ),
            const SizedBox(height: 12),
            orders.when(
              loading: () => const LoadingState(),
              error: (_, _) => LoadError(
                onRetry: () => ref.invalidate(ordersPageProvider(null)),
              ),
              data: (page) {
                final active = page.items
                    .where(
                      (o) =>
                          o.text('customerId') == session.userId &&
                          !o.status.terminal,
                    )
                    .take(3)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (active.isEmpty)
                      const Text(
                        'Tidak ada servis aktif dari 20 SO terbaru. Buka daftar untuk memeriksa halaman lain.',
                      ),
                    for (final order in active)
                      _CustomerRecord(
                        title: order.text('vehiclePlate'),
                        subtitle:
                            '${order.text('vehicleName')}\n${order.text('serviceName')}',
                        icon: Icons.build_outlined,
                        status: StatusChip(
                          label: order.status.label,
                          tone: orderStatusTone(order.status),
                        ),
                        onTap: () => context.go('/customer/orders/${order.id}'),
                      ),
                  ],
                );
              },
            ),
            bookings.when(
              loading: () => const LoadingState(),
              error: (_, _) =>
                  LoadError(onRetry: () => ref.invalidate(bookingsProvider)),
              data: (items) => Column(
                children: [
                  for (final booking
                      in items
                          .where(
                            (b) =>
                                b.customerId == session.userId &&
                                b.status.isActive,
                          )
                          .take(3))
                    _CustomerRecord(
                      title: booking.vehicle.plate,
                      subtitle:
                          '${booking.vehicle.name}\n${booking.draft.service}\n${bookingSchedule(booking.draft.scheduledAt)}',
                      icon: Icons.event_note_outlined,
                      status: StatusChip(
                        label: booking.status.label,
                        tone: booking.status.name == 'pending'
                            ? StatusChipTone.warning
                            : StatusChipTone.success,
                      ),
                      onTap: () =>
                          context.go('/customer/bookings/${booking.id}'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuplikan hingga 3 servis dari 20 SO dan 3 booking aktif dari 100 booking terbaru Anda.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Menu lainnya'),
              children: [
                for (final action in const [
                  (
                    'Booking Saya',
                    Icons.event_note_outlined,
                    '/customer/bookings',
                  ),
                  (
                    'Progres Servis',
                    Icons.car_repair_outlined,
                    '/customer/orders',
                  ),
                  (
                    'Invoice & Pembayaran',
                    Icons.receipt_long_outlined,
                    '/customer/invoices',
                  ),
                ])
                  ListTile(
                    leading: Icon(action.$2),
                    title: Text(action.$1),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go(action.$3),
                  ),
              ],
            ),
            ExpansionTile(
              title: const Text('Ringkasan booking'),
              children: [
                bookings.when(
                  loading: () => const LoadingState(),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(bookingsProvider),
                  ),
                  data: (items) {
                    final own = items.where(
                      (b) => b.customerId == session.userId,
                    );
                    return Column(
                      children: [
                        Text(
                          'Booking aktif: ${own.where((b) => b.status.isActive).length}',
                        ),
                        Text(
                          'Booking dikonfirmasi: ${own.where((b) => b.status.name == 'confirmed').length}',
                        ),
                        const Text(
                          'Ringkasan dari maksimal 100 booking terbaru Anda.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Kendaraan terdaftar'),
              children: [
                ref
                    .watch(vehiclesProvider)
                    .when(
                      loading: () => const LoadingState(),
                      error: (_, _) => LoadError(
                        onRetry: () => ref.invalidate(vehiclesProvider),
                      ),
                      data: (vehicles) => Column(
                        children: [
                          Text(
                            '${vehicles.length} kendaraan aktif dimuat, maksimal 50.',
                          ),
                          for (final vehicle in vehicles.take(3))
                            ListTile(
                              leading: const Icon(
                                Icons.directions_car_outlined,
                              ),
                              title: Text(vehicle.plate),
                              subtitle: Text(vehicle.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go('/customer/vehicles'),
                            ),
                          TextButton(
                            onPressed: () => context.go('/customer/vehicles'),
                            child: const Text('Kelola kendaraan'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
            const ExpansionTile(
              title: Text('Booking terbaru'),
              children: [BookingListContent(customer: true, limit: 3)],
            ),
            ExpansionTile(
              title: const Text('Riwayat servis terbaru'),
              children: [
                ref
                    .watch(historyPageProvider(const HistoryFilter()))
                    .when(
                      loading: () => const LoadingState(),
                      error: (_, _) => LoadError(
                        onRetry: () => ref.invalidate(historyPageProvider),
                      ),
                      data: (page) => Column(
                        children: [
                          if (page.fromCache)
                            const Text(
                              'Offline/cache: riwayat mungkin belum lengkap.',
                            ),
                          if (page.items.isEmpty)
                            const Text(
                              'Belum ada riwayat servis pada halaman ini.',
                            ),
                          for (final order in page.items.take(3))
                            ListTile(
                              leading: const Icon(
                                Icons.task_alt,
                                color: AppColors.success,
                              ),
                              title: Text(
                                '${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                              ),
                              subtitle: Text(
                                '${order.text('serviceName')}\n${historyDate(order.date('completedAt'))}',
                              ),
                              onTap: () =>
                                  context.go('/customer/history/${order.id}'),
                            ),
                          TextButton(
                            onPressed: () => context.go('/customer/history'),
                            child: const Text('Lihat semua riwayat'),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: const BorderSide(color: AppColors.blueBorder),
);

class _CustomerMetric extends StatelessWidget {
  const _CustomerMetric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _CustomerRecord extends StatelessWidget {
  const _CustomerRecord({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.status,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    shape: _shape,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(subtitle), const SizedBox(height: 6), status],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
