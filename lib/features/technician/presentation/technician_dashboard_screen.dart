import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/dashboard_stat_card.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Halo, Teknisi',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.read(authSessionProvider.notifier).signOut();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: const [
                DashboardStatCard(
                  label: 'Ditugaskan',
                  value: '5',
                  icon: Icons.assignment_rounded,
                  color: AppColors.primary,
                ),
                DashboardStatCard(
                  label: 'Sedang Dikerjakan',
                  value: '2',
                  icon: Icons.build_circle_rounded,
                  color: AppColors.warning,
                ),
                DashboardStatCard(
                  label: 'Selesai Hari Ini',
                  value: '3',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Pekerjaan Hari Ini'),
            const SizedBox(height: 12),
            const _ServiceJobCard(
              serviceOrder: 'SO-2026-001',
              vehicleName: 'Honda Brio',
              plateNumber: 'B 1234 XYZ',
              time: '09:00',
              status: 'Menunggu',
              tone: StatusChipTone.warning,
            ),
            const SizedBox(height: 12),
            const _ServiceJobCard(
              serviceOrder: 'SO-2026-002',
              vehicleName: 'Toyota Avanza',
              plateNumber: 'N 1234 AB',
              time: '10:30',
              status: 'Sedang Dikerjakan',
              tone: StatusChipTone.info,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Lihat Semua Pekerjaan',
                    onPressed: () => context.go('/technician/jobs'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Riwayat Pekerjaan',
                    onPressed: () {},
                    isOutlined: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Aktivitas Terbaru'),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  QuickActionCard(
                    title: 'Checklist',
                    icon: Icons.fact_check_rounded,
                    color: AppColors.success,
                    onTap: () => context.go('/technician/jobs'),
                  ),
                  QuickActionCard(
                    title: 'Progres',
                    icon: Icons.timeline_rounded,
                    color: AppColors.primary,
                    onTap: () => context.go('/technician/jobs'),
                  ),
                  QuickActionCard(
                    title: 'Stok',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.accent,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Beranda'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.work_history_rounded),
                  label: Text('Pekerjaan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_rounded),
                  label: Text('Riwayat'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: Text('Profil'),
                ),
              ],
              selectedIndex: 0,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_history_rounded),
            label: 'Pekerjaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ServiceJobCard extends StatelessWidget {
  const _ServiceJobCard({
    required this.serviceOrder,
    required this.vehicleName,
    required this.plateNumber,
    required this.time,
    required this.status,
    required this.tone,
  });

  final String serviceOrder;
  final String vehicleName;
  final String plateNumber;
  final String time;
  final String status;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceOrder,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicleName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    plateNumber,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(time, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 16),
            StatusChip(label: status, tone: tone),
          ],
        ),
      ),
    );
  }
}

