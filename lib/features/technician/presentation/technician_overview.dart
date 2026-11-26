import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:bengkel_kendaraan/features/auth/data/auth_repository.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/order_parts_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_completion_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technician_task_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TechnicianOverview extends ConsumerWidget {
  const TechnicianOverview({super.key});

  Future<void> choosePartsTask(
    BuildContext context,
    List<ServiceOrder> tasks,
  ) async {
    final picked = await showModalBottomSheet<ServiceOrder>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            Text(
              'Pilih tugas untuk permintaan sparepart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final task in tasks)
              TechnicianTaskCard(
                order: task,
                onTap: () => Navigator.pop(context, task),
              ),
          ],
        ),
      ),
    );
    if (picked != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartRequestScreen(orderId: picked.id),
        ),
      );
    }
  }

  int _progressStep(ServiceOrderStatus status) => switch (status) {
        ServiceOrderStatus.queued || ServiceOrderStatus.assigned => 0,
        ServiceOrderStatus.inProgress ||
        ServiceOrderStatus.paused ||
        ServiceOrderStatus.awaitingApproval => 1,
        ServiceOrderStatus.completed || ServiceOrderStatus.cancelled => 2,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final orders = ref.watch(ordersPageProvider(null));

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
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(ordersPageProvider(null)),
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go('/technician/profile'),
          ),
        ],
      ),
      bottomNavigationBar: const MobileNavigation(role: 'technician'),
      body: WorkshopBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Text(
              'Halo, Teknisi',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pantau tugas aktif, perbarui checklist, dan ajukan kebutuhan sparepart.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 16),
            orders.when(
              loading: () => const LoadingState(),
              error: (_, _) => RetryLoad(
                onRetry: () => ref.invalidate(ordersPageProvider(null)),
              ),
              data: (page) {
                final own = page.items
                    .where((o) => o.technicianId == session.userId)
                    .toList();
                final assigned = own
                    .where((o) => o.status == ServiceOrderStatus.assigned)
                    .toList();
                final inProgress = own
                    .where(
                      (o) =>
                          o.status == ServiceOrderStatus.inProgress ||
                          o.status == ServiceOrderStatus.paused,
                    )
                    .toList();
                final approval = own
                    .where(
                      (o) => o.status == ServiceOrderStatus.awaitingApproval,
                    )
                    .toList();
                final completed = own
                    .where((o) => o.status == ServiceOrderStatus.completed)
                    .toList();
                final partEligible = [...inProgress];
                final lead = [
                  ...inProgress,
                  ...assigned,
                  ...approval,
                ].firstOrNull;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lead != null)
                      CarbonSpotlightCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UniversalVehicleThumb(
                                  vehicleName: lead.text('vehicleName'),
                                  size: 50,
                                  darkSurface: true,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'FOKUS PEKERJAAN',
                                        style: TextStyle(
                                          color: AppColors.accentLight,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lead.text('vehicleName'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        lead.text('serviceName'),
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
                                IndonesianPlateBadge(
                                  plate: lead.text('vehiclePlate'),
                                  dark: true,
                                ),
                                TechnicianStatus(status: lead.status),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ServiceProgressStrip(
                              activeStep: _progressStep(lead.status),
                              labels: const ['Menunggu', 'Diproses', 'Selesai'],
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              onPressed: () =>
                                  context.go('/technician/orders/${lead.id}'),
                              child: const Text('Buka Detail Tugas'),
                            ),
                          ],
                        ),
                      )
                    else
                      CarbonSpotlightCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'STATUS KERJA',
                              style: TextStyle(
                                color: AppColors.accentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Belum ada tugas aktif',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tugas baru dari admin bengkel akan langsung muncul di sini.',
                              style: TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TechnicianSummary(
                      total: own.length,
                      inProgress: inProgress.length,
                      completed: completed.length,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aksi Cepat Teknisi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TechnicianShortcut(
                      icon: Icons.assignment_outlined,
                      title: 'Daftar Tugas Servis',
                      subtitle: 'Lihat semua pekerjaan yang ditugaskan',
                      onTap: () => context.go('/technician/jobs'),
                    ),
                    TechnicianShortcut(
                      icon: Icons.inventory_2_outlined,
                      title: 'Permintaan Sparepart',
                      subtitle: partEligible.isEmpty
                          ? 'Mulai kerjakan tugas untuk meminta sparepart'
                          : 'Ajukan part untuk ${partEligible.length} tugas aktif',
                      onTap: partEligible.isEmpty
                          ? null
                          : () => choosePartsTask(context, partEligible),
                    ),
                    TechnicianShortcut(
                      icon: Icons.fact_check_outlined,
                      title: 'Ajukan Penyelesaian',
                      subtitle: lead == null
                          ? 'Belum ada tugas siap diajukan'
                          : 'Kirim ringkasan ${lead.text('vehiclePlate')} ke admin',
                      onTap: lead == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceCompletionScreen(orderId: lead.id),
                                ),
                              ),
                    ),
                    if (own.any((o) => !o.status.terminal)) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Antrean Tugas Anda',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      for (final task
                          in own.where((o) => !o.status.terminal).take(3))
                        TechnicianTaskCard(
                          order: task,
                          onTap: () =>
                              context.go('/technician/orders/${task.id}'),
                        ),
                    ],
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

class TechnicianSummary extends StatelessWidget {
  const TechnicianSummary({
    super.key,
    required this.total,
    required this.inProgress,
    required this.completed,
  });

  final int total;
  final int inProgress;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          if (stacked) {
            final halfW = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: halfW,
                  child: _TechMetric(label: 'Total', value: '$total'),
                ),
                SizedBox(
                  width: halfW,
                  child: _TechMetric(
                    label: 'Diproses',
                    value: '$inProgress',
                    accent: true,
                  ),
                ),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _TechMetric(label: 'Selesai', value: '$completed'),
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(
                child: _TechMetric(label: 'Total', value: '$total'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TechMetric(
                  label: 'Diproses',
                  value: '$inProgress',
                  accent: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TechMetric(label: 'Selesai', value: '$completed'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TechMetric extends StatelessWidget {
  const _TechMetric({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: accent ? AppColors.accentSoft : AppColors.background,
        borderRadius: BorderRadius.circular(14),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TechnicianShortcut extends StatelessWidget {
  const TechnicianShortcut({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.accentSoft : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.secondary : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: enabled ? AppColors.primary : AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled ? AppColors.primary : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
