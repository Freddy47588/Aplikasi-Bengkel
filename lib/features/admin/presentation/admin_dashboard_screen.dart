import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/dashboard_stat_card.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
                Expanded(
                  child: Text(
                    'Dashboard Bengkel',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
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
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.6 : 1.7,
              children: const [
                DashboardStatCard(
                  label: 'Booking Hari Ini',
                  value: '24',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.primary,
                ),
                DashboardStatCard(
                  label: 'Sedang Servis',
                  value: '8',
                  icon: Icons.build_circle_rounded,
                  color: AppColors.warning,
                ),
                DashboardStatCard(
                  label: 'Selesai Hari Ini',
                  value: '13',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                DashboardStatCard(
                  label: 'Pendapatan Hari Ini',
                  value: 'Rp8.750.000',
                  icon: Icons.attach_money_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Quick Menu'),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                QuickActionCard(
                  title: 'Booking',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  onTap: () => context.go('/admin/bookings'),
                ),
                QuickActionCard(
                  title: 'Antrean',
                  icon: Icons.queue_rounded,
                  color: AppColors.secondary,
                  onTap: () => context.go('/admin/bookings'),
                ),
                QuickActionCard(
                  title: 'Service Order',
                  icon: Icons.fact_check_rounded,
                  color: AppColors.accent,
                  onTap: () => context.go('/admin/bookings'),
                ),
                QuickActionCard(
                  title: 'Teknisi',
                  icon: Icons.engineering_rounded,
                  color: AppColors.warning,
                  onTap: () => context.go('/technician/jobs'),
                ),
                QuickActionCard(
                  title: 'Sparepart',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.success,
                  onTap: () {},
                ),
                QuickActionCard(
                  title: 'Customer',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                  onTap: () {},
                ),
                QuickActionCard(
                  title: 'Pembayaran',
                  icon: Icons.payments_rounded,
                  color: AppColors.secondary,
                  onTap: () {},
                ),
                QuickActionCard(
                  title: 'Laporan',
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.danger,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Aktivitas Terbaru'),
                        const SizedBox(height: 12),
                        _ActivityList(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Stok Menipis'),
                        const SizedBox(height: 12),
                        _LowStockList(),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              SectionHeader(title: 'Aktivitas Terbaru'),
              const SizedBox(height: 12),
              _ActivityList(),
              const SizedBox(height: 24),
              SectionHeader(title: 'Stok Menipis'),
              const SizedBox(height: 12),
              _LowStockList(),
            ],
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
                  icon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: Text('Booking'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: Text('Operasional'),
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
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Laporan',
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

class _ActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      'Booking BKG-001 dikonfirmasi',
      'Service SO-002 mulai dikerjakan',
      'Pembayaran INV-003 berhasil',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(items.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _LowStockList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': 'Oli Shell HX7', 'count': '3 pcs'},
      {'name': 'Kampas Rem Bendix', 'count': '2 pcs'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          item['count']!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
