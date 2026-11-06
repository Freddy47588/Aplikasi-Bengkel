import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/technician/presentation/service_orders_screen.dart';
import '../data/booking_repository.dart';
import '../data/inventory_repository.dart';
import '../data/service_history_repository.dart';
import '../data/vehicle_repository.dart';
import '../models/service_history.dart';
import '../models/service_order.dart';
import 'dashboard_stat_card.dart';
import 'empty_state.dart';
import 'foundation_pages.dart';
import 'logout_button.dart';
import 'mobile_navigation.dart';
import 'quick_action_card.dart';
import 'section_header.dart';
import 'service_timeline.dart';
import 'status_chip.dart';
import 'workshop_ui.dart';

class LiveDashboard extends ConsumerWidget {
  const LiveDashboard({
    super.key,
    required this.customer,
    this.technician = false,
  });
  final bool customer, technician;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final role = customer
        ? 'customer'
        : technician
        ? 'technician'
        : 'admin';
    final orders = ref.watch(ordersPageProvider(null));
    final identity = session.email?.split('@').first;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final actions = <(String, IconData, String)>[
      if (customer) ...[
        ('Booking Servis', Icons.event_available_outlined, '/customer/booking'),
        ('Kendaraan Saya', Icons.directions_car_outlined, '/customer/vehicles'),
        ('Booking Saya', Icons.event_note_outlined, '/customer/bookings'),
      ] else if (technician) ...[
        ('Pekerjaan Saya', Icons.build_outlined, '/technician/jobs'),
      ] else ...[
        ('Kelola Booking', Icons.event_available_outlined, '/admin/bookings'),
        ('Inventory Sparepart', Icons.inventory_2_outlined, '/admin/inventory'),
        ('Manajemen Teknisi', Icons.engineering_outlined, '/admin/technicians'),
      ],
      ('Progres Servis', Icons.car_repair_outlined, '/$role/orders'),
      ('Riwayat Servis', Icons.history, '/$role/history'),
      if (!technician)
        (
          'Invoice & Pembayaran',
          Icons.receipt_long_outlined,
          '/$role/invoices',
        ),
    ];
    final bookingSummary = !technician
        ? ref
              .watch(bookingsProvider)
              .when(
                loading: () => const LoadingState(),
                error: (_, _) =>
                    LoadError(onRetry: () => ref.invalidate(bookingsProvider)),
                data: (items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AdaptiveCards(
                      minWidth: largeText ? 240 : 128,
                      children: [
                        DashboardStatCard(
                          compact: true,
                          label: customer
                              ? 'Booking aktif'
                              : 'Menunggu konfirmasi',
                          value:
                              '${items.where((b) => customer ? b.status.isActive : b.status.name == 'pending').length}',
                          icon: Icons.event_available_outlined,
                          color: AppColors.warning,
                        ),
                        DashboardStatCard(
                          compact: true,
                          label: 'Booking dikonfirmasi',
                          value:
                              '${items.where((b) => b.status.name == 'confirmed').length}',
                          icon: Icons.fact_check_outlined,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Ringkasan dari maksimal 100 booking terbaru.',
                      ),
                    ),
                  ],
                ),
              )
        : const SizedBox.shrink();
    final orderSummary = orders.when(
      loading: () => const LoadingState(),
      error: (_, _) =>
          LoadError(onRetry: () => ref.invalidate(ordersPageProvider(null))),
      data: (page) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveCards(
            minWidth: largeText ? 240 : 128,
            children: [
              DashboardStatCard(
                compact: true,
                label: technician
                    ? 'Tugas aktif pada halaman ini'
                    : 'Servis aktif pada halaman ini',
                value: '${page.items.where((o) => !o.status.terminal).length}',
                icon: Icons.car_repair_outlined,
                color: AppColors.info,
              ),
              DashboardStatCard(
                compact: true,
                label: 'Selesai pada halaman ini',
                value:
                    '${page.items.where((o) => o.status == ServiceOrderStatus.completed).length}',
                icon: Icons.task_alt,
                color: AppColors.success,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Maksimal 20 Service Order terbaru; bukan total seluruh bengkel.',
            ),
          ),
        ],
      ),
    );
    final progress = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: technician ? 'Pekerjaan aktif' : 'Progres kendaraan',
          actionLabel: 'Lihat semua',
          onPressed: () => context.go('/$role/orders'),
        ),
        const SizedBox(height: 12),
        orders.when(
          loading: () => const LoadingState(),
          error: (_, _) => LoadError(
            onRetry: () => ref.invalidate(ordersPageProvider(null)),
          ),
          data: (page) {
            final active = page.items
                .where((o) => !o.status.terminal)
                .take(3)
                .toList();
            if (active.isEmpty) {
              return const EmptyState(
                title: 'Tidak ada servis aktif pada halaman ini',
                description:
                    'Buka daftar untuk melihat seluruh halaman pekerjaan.',
                icon: Icons.car_repair_outlined,
              );
            }
            return Column(
              children: [
                for (final order in active)
                  ContentSection(
                    title: order.text('vehicleName'),
                    children: [
                      Text(
                        '${order.text('vehiclePlate')} • ${order.text('serviceName')}',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(
                          label: order.status.label,
                          tone: orderStatusTone(order.status),
                        ),
                      ),
                      if (customer) ServiceTimeline(order: order),
                      TextButton.icon(
                        onPressed: () =>
                            context.go('/$role/orders/${order.id}'),
                        icon: const Icon(Icons.chevron_right),
                        label: Text(
                          technician
                              ? 'Buka tugas & tindakan berikutnya'
                              : 'Detail progres',
                        ),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
    final quickActions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Akses cepat'),
        const SizedBox(height: 12),
        AdaptiveCards(
          minWidth: largeText ? 240 : 140,
          children: [
            for (final action in actions.skip(1))
              QuickActionCard(
                title: action.$1,
                icon: action.$2,
                color: AppColors.secondary,
                onTap: () => context.go(action.$3),
              ),
          ],
        ),
      ],
    );
    final bookings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: customer ? 'Booking terbaru' : 'Antrean booking',
          actionLabel: 'Lihat semua',
          onPressed: () => context.go('/$role/bookings'),
        ),
        const SizedBox(height: 12),
        BookingListContent(customer: customer, limit: 3),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('BengkelKu'),
        actions: const [LogoutButton(icon: true)],
      ),
      bottomNavigationBar: MobileNavigation(role: role),
      body: WorkshopBody(
        showWave: customer,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WorkshopHero(
              compact: !customer,
              art: customer
                  ? WorkshopArt.vehicles
                  : technician
                  ? WorkshopArt.technician
                  : WorkshopArt.garage,
              eyebrow: customer
                  ? 'Garasi pelanggan'
                  : technician
                  ? 'Ruang teknisi'
                  : 'Kendali bengkel',
              title: identity == null || identity.isEmpty
                  ? (technician
                        ? 'Pekerjaan teknisi'
                        : 'Selamat datang di BengkelKu')
                  : 'Halo, $identity',
              description: customer
                  ? 'Booking dan riwayat servis kendaraan Anda.'
                  : technician
                  ? 'Lihat tugas dan catat hasil pemeriksaan kendaraan.'
                  : 'Kelola booking dan pekerjaan bengkel.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go(actions.first.$3),
              icon: Icon(actions.first.$2),
              label: Text(actions.first.$1),
            ),
            const SizedBox(height: 24),
            if (technician) ...[
              progress,
              const SizedBox(height: 24),
              const SectionHeader(title: 'Ringkasan aktivitas'),
              const SizedBox(height: 12),
              orderSummary,
              const SizedBox(height: 24),
              quickActions,
            ] else ...[
              const SectionHeader(title: 'Ringkasan aktivitas'),
              const SizedBox(height: 12),
              bookingSummary,
              if (!customer) ...[
                const SizedBox(height: 24),
                bookings,
                const SizedBox(height: 24),
                orderSummary,
              ] else ...[
                const SizedBox(height: 16),
                quickActions,
              ],
              const SizedBox(height: 24),
              progress,
              if (customer) ...[const SizedBox(height: 24), orderSummary],
            ],
            if (!customer && !technician) ...[
              const SizedBox(height: 24),
              ref
                  .watch(
                    inventoryPageProvider((
                      cursor: null,
                      search: '',
                      category: '',
                      active: true,
                      lowOnly: true,
                    )),
                  )
                  .when(
                    loading: () => const LoadingState(),
                    error: (_, _) => LoadError(
                      onRetry: () => ref.invalidate(inventoryPageProvider),
                    ),
                    data: (page) => ContentSection(
                      title: 'Perhatian stok',
                      children: [
                        Text(
                          '${page.items.length}${page.hasMore ? '+' : ''} sparepart aktif perlu diperiksa pada hasil ini.',
                        ),
                        for (final part in page.items.take(3))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.warning,
                            ),
                            title: Text(part.text('name')),
                            subtitle: Text(
                              'Stok ${part.stock} ${part.text('unit')} • batas ${part.number('minimumStock')}',
                            ),
                            onTap: () => context.go('/admin/inventory'),
                          ),
                        const Text(
                          'Hasil terbatas per halaman. Buka inventory untuk memeriksa seluruh stok rendah.',
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 24),
              quickActions,
            ],
            if (customer) ...[
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Kendaraan terdaftar',
                actionLabel: 'Kelola',
                onPressed: () => context.go('/customer/vehicles'),
              ),
              ref
                  .watch(vehiclesProvider)
                  .when(
                    loading: () => const LoadingState(),
                    error: (_, _) => LoadError(
                      onRetry: () => ref.invalidate(vehiclesProvider),
                    ),
                    data: (vehicles) => vehicles.isEmpty
                        ? const EmptyState(
                            title: 'Garasi Anda masih kosong',
                            description:
                                'Tambahkan kendaraan untuk mulai booking servis.',
                            icon: Icons.directions_car_outlined,
                          )
                        : ContentSection(
                            title:
                                '${vehicles.length} kendaraan aktif • maks. 50',
                            children: [
                              for (final v in vehicles.take(3))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.directions_car_outlined,
                                  ),
                                  title: Text(v.name),
                                  subtitle: Text(v.plate),
                                  onTap: () => context.go('/customer/vehicles'),
                                ),
                            ],
                          ),
                  ),
              const SizedBox(height: 24),
              bookings,
            ],
            const SizedBox(height: 24),
            SectionHeader(
              title: 'Riwayat servis terbaru',
              actionLabel: 'Lihat semua',
              onPressed: () => context.go('/$role/history'),
            ),
            ref
                .watch(historyPageProvider(const HistoryFilter()))
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) => LoadError(
                    onRetry: () => ref.invalidate(historyPageProvider),
                  ),
                  data: (page) => ContentSection(
                    title: 'Servis selesai',
                    children: [
                      if (page.fromCache)
                        const Text(
                          'Offline/cache: riwayat mungkin belum lengkap.',
                        ),
                      if (page.items.isEmpty)
                        const Text(
                          'Belum ada riwayat servis pada halaman ini.',
                        ),
                      for (final o in page.items.take(3))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.task_alt,
                            color: AppColors.success,
                          ),
                          title: Text(
                            '${o.text('vehicleName')} • ${o.text('vehiclePlate')}',
                          ),
                          subtitle: Text(
                            '${o.text('serviceName')}\n${historyDate(o.date('completedAt'))}',
                          ),
                          onTap: () => context.go('/$role/history/${o.id}'),
                        ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
