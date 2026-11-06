import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/data/service_history_repository.dart';
import '../../../core/models/service_history.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../auth/data/auth_repository.dart';
import '../../inventory/presentation/order_parts_screen.dart';
import 'service_orders_screen.dart';
import 'technician_task_ui.dart';

class TechnicianOverview extends ConsumerWidget {
  const TechnicianOverview({super.key});

  Future<void> choosePartsTask(
    BuildContext context,
    List<ServiceOrder> orders,
  ) async {
    final eligible = orders
        .where(
          (o) => [
            ServiceOrderStatus.inProgress,
            ServiceOrderStatus.paused,
          ].contains(o.status),
        )
        .toList();
    final selected = await showModalBottomSheet<ServiceOrder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .75,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                'Permintaan Sparepart',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Pilih tugas yang sedang dikerjakan atau dijeda dari 20 tugas terbaru Anda.',
              ),
              const SizedBox(height: 16),
              if (eligible.isEmpty)
                const EmptyState(
                  title: 'Belum ada tugas yang dapat dipilih',
                  description:
                      'Mulai tugas Anda sebelum meminta sparepart. Tugas pada halaman lain dapat dibuka dari Tugas Saya.',
                  icon: Icons.inventory_2_outlined,
                ),
              for (final order in eligible)
                TechnicianTaskCard(
                  order: order,
                  onTap: () => Navigator.pop(sheetContext, order),
                ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/technician/jobs');
                },
                child: const Text('Lihat semua tugas'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartRequestScreen(orderId: selected.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated || session.role != UserRole.technician) {
      return const SizedBox.shrink();
    }
    final orders = ref.watch(ordersPageProvider(null));
    final identity = session.email?.split('@').first;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Selamat Datang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: const [LogoutButton(icon: true)],
      ),
      bottomNavigationBar: const MobileNavigation(role: 'technician'),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          children: [
            Text(
              identity == null || identity.isEmpty
                  ? 'Teknisi BengkelKu'
                  : 'Halo, $identity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Lihat ringkasan tugas Anda dan kelola pekerjaan servis.',
            ),
            if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: WorkshopIllustration(
                      WorkshopArt.technician,
                      height: 112,
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: WorkshopIllustration(
                      WorkshopArt.garage,
                      height: 112,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            orders.when(
              loading: () => const LoadingState(),
              error: (_, _) => LoadError(
                onRetry: () => ref.invalidate(ordersPageProvider(null)),
              ),
              data: (page) {
                final own = page.items
                    .where((o) => o.technicianId == session.userId)
                    .toList();
                final active = own.where((o) => !o.status.terminal).take(3);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TechnicianSummary(orders: own),
                    const SizedBox(height: 6),
                    Text(
                      'Maksimal 20 tugas terbaru Anda; bukan ringkasan harian.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(
                      title: 'Pekerjaan Aktif',
                      actionLabel: 'Lihat semua',
                      onPressed: () => context.go('/technician/orders'),
                    ),
                    const SizedBox(height: 10),
                    if (active.isEmpty)
                      const EmptyState(
                        title: 'Tidak ada servis aktif pada halaman ini',
                        description:
                            'Buka daftar untuk melihat seluruh halaman pekerjaan.',
                        icon: Icons.car_repair_outlined,
                      ),
                    for (final order in active)
                      TechnicianTaskCard(
                        order: order,
                        onTap: () =>
                            context.go('/technician/orders/${order.id}'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            const SectionHeader(title: 'Menu Cepat'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, box) {
                final tiles = <Widget>[
                  TechnicianShortcut(
                    icon: Icons.build_outlined,
                    title: 'Tugas Saya',
                    onTap: () => context.go('/technician/jobs'),
                  ),
                  TechnicianShortcut(
                    icon: Icons.assignment_outlined,
                    title: 'Riwayat Pekerjaan',
                    onTap: () => context.go('/technician/history'),
                  ),
                  TechnicianShortcut(
                    icon: Icons.inventory_2_outlined,
                    title: 'Permintaan Sparepart',
                    onTap: orders.asData == null
                        ? null
                        : () => choosePartsTask(
                            context,
                            orders.asData?.value.items
                                    .where(
                                      (o) => o.technicianId == session.userId,
                                    )
                                    .toList() ??
                                [],
                          ),
                  ),
                ];
                if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                    box.maxWidth < 280) {
                  return Column(
                    children: [
                      for (final tile in tiles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: tile,
                        ),
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < tiles.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(child: tiles[i]),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.go('/technician/orders'),
              icon: const Icon(Icons.car_repair_outlined),
              label: const Text('Progres Servis'),
            ),
            const SizedBox(height: 12),
            SectionHeader(
              title: 'Riwayat servis terbaru',
              actionLabel: 'Lihat semua',
              onPressed: () => context.go('/technician/history'),
            ),
            const SizedBox(height: 10),
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
                      for (final order in page.items.take(3))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.task_alt,
                            color: AppColors.success,
                          ),
                          title: Text(
                            '${order.text('vehicleName')} · ${order.text('vehiclePlate')}',
                          ),
                          subtitle: Text(
                            '${order.text('serviceName')}\n${historyDate(order.date('completedAt'))}',
                          ),
                          onTap: () =>
                              context.go('/technician/history/${order.id}'),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class TechnicianSummary extends StatelessWidget {
  const TechnicianSummary({super.key, required this.orders});
  final List<ServiceOrder> orders;
  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.blueBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ringkasan Pekerjaan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final stats = [
                ('Total Tugas', orders.length),
                (
                  'Sedang Dikerjakan',
                  orders
                      .where((o) => o.status == ServiceOrderStatus.inProgress)
                      .length,
                ),
                (
                  'Selesai',
                  orders
                      .where((o) => o.status == ServiceOrderStatus.completed)
                      .length,
                ),
              ];
              final cells = [
                for (final (label, count) in stats)
                  Column(
                    children: [
                      Text(
                        '$count',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
              ];
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                return Column(
                  children: [
                    for (final cell in cells)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: cell,
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final cell in cells) Expanded(child: cell)],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class TechnicianShortcut extends StatelessWidget {
  const TechnicianShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.controlBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: onTap == null ? AppColors.muted : AppColors.primary,
            ),
          ),
        ],
      ),
    ),
  );
}
