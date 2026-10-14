import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/quick_action_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_chip.dart';

class CustomerDashboardScreen extends ConsumerWidget {
  const CustomerDashboardScreen({super.key});

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, Achmad 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selamat datang kembali.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Honda Brio RS',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'B 1234 XYZ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '2022',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const StatusChip(
                      label: 'Siap',
                      tone: StatusChipTone.success,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Service aktif'),
            const SizedBox(height: 12),
            const EmptyState(
              title: 'Belum ada servis aktif',
              description: 'Booking dan status servis akan muncul di sini.',
            ),
            const SizedBox(height: 24),
            SectionHeader(title: 'Quick Action'),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  QuickActionCard(
                    title: 'Booking Servis',
                    icon: Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    onTap: () => context.go('/customer/booking'),
                  ),
                  QuickActionCard(
                    title: 'Kendaraan Saya',
                    icon: Icons.car_repair_rounded,
                    color: AppColors.secondary,
                    onTap: () {},
                  ),
                  QuickActionCard(
                    title: 'Riwayat Servis',
                    icon: Icons.history_rounded,
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                  QuickActionCard(
                    title: 'Pembayaran',
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                    onTap: () {},
                  ),
                ],
              ),
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
                        SectionHeader(title: 'Booking Berikutnya'),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BengkelKu - Service Berkala',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Jumat, 09:30 - 11:00',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                AppPrimaryButton(
                                  label: 'Detail Booking',
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(title: 'Riwayat Terakhir'),
                        const SizedBox(height: 12),
                        _HistoryCard(
                          title: 'Ganti Oli & Filter',
                          date: '12 Sep 2026',
                          amount: 'Rp 540.000',
                        ),
                        const SizedBox(height: 12),
                        _HistoryCard(
                          title: 'Tune Up',
                          date: '03 Sep 2026',
                          amount: 'Rp 820.000',
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              SectionHeader(title: 'Booking Berikutnya'),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BengkelKu - Service Berkala',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jumat, 09:30 - 11:00',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: 'Detail Booking',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Riwayat Terakhir'),
              const SizedBox(height: 12),
              _HistoryCard(
                title: 'Ganti Oli & Filter',
                date: '12 Sep 2026',
                amount: 'Rp 540.000',
              ),
              const SizedBox(height: 12),
              _HistoryCard(
                title: 'Tune Up',
                date: '03 Sep 2026',
                amount: 'Rp 820.000',
              ),
            ],
            const SizedBox(height: 24),
            SectionHeader(title: 'Informasi Servis'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationRow(
                      title: 'Reminder servis: 2,500 km',
                      subtitle: 'Silakan booking terlebih dahulu untuk menjaga performa kendaraan.',
                    ),
                    const SizedBox(height: 16),
                    _NotificationRow(
                      title: 'Pembayaran terverifikasi',
                      subtitle: 'Pembayaran Service Berkala dengan nomor INV-2048 telah berhasil.',
                    ),
                  ],
                ),
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
              extended: false,
              backgroundColor: AppColors.surface,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_rounded),
                  label: Text('Beranda'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.calendar_month_rounded),
                  label: Text('Booking'),
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
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Booking',
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.date,
    required this.amount,
  });

  final String title;
  final String date;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(date, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
