import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

/// Floating pill bottom navigation tailored per workshop role.
class MobileNavigation extends StatelessWidget {
  const MobileNavigation({super.key, required this.role});

  final String role;

  static List<(String route, String label, IconData icon)> destinationsFor(
    String role,
  ) => switch (role) {
    'admin' => const [
      ('home', 'Beranda', Icons.home_rounded),
      ('bookings', 'Order', Icons.assignment_rounded),
      ('inventory', 'Stok', Icons.inventory_2_rounded),
      ('invoices', 'Kasir', Icons.receipt_long_rounded),
      ('profile', 'Profil', Icons.person_rounded),
    ],
    'technician' => const [
      ('home', 'Beranda', Icons.home_rounded),
      ('jobs', 'Tugas', Icons.build_rounded),
      ('history', 'Riwayat', Icons.history_rounded),
      ('profile', 'Profil', Icons.person_rounded),
    ],
    _ => const [
      ('home', 'Beranda', Icons.home_rounded),
      ('booking', 'Booking', Icons.calendar_month_rounded),
      ('orders', 'Servis', Icons.build_rounded),
      ('profile', 'Profil', Icons.person_rounded),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final destinations = destinationsFor(role);
    final path = GoRouterState.of(context).uri.path;
    final rawIndex =
        navigationIndex(role, path) ??
        destinations.indexWhere(
          (d) => path == '/$role/${d.$1}' || path.startsWith('/$role/${d.$1}/'),
        );
    final selectedIndex = rawIndex < 0 ? 0 : rawIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      flex: i == selectedIndex ? 2 : 1,
                      child: _PillNavItem(
                        label: destinations[i].$2,
                        icon: destinations[i].$3,
                        selected: i == selectedIndex,
                        onTap: () => context.go('/$role/${destinations[i].$1}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  const _PillNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 8 : 2,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.accentLight : AppColors.muted,
                ),
                if (selected) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(message: label, child: pill),
    );
  }
}

/// Maps active route paths (including nested details) to bottom bar index.
int? navigationIndex(String role, String path) {
  final section = path
      .split('/')
      .where((s) => s.isNotEmpty)
      .skip(1)
      .firstOrNull;
  if (section == 'home') return 0;
  if (role == 'admin') {
    if (['bookings', 'orders', 'technicians', 'history'].contains(section)) {
      return 1;
    }
    if (section == 'inventory') return 2;
    if (section == 'invoices') return 3;
    if (section == 'profile') return 4;
  }
  if (role == 'customer') {
    if (['booking', 'bookings'].contains(section)) return 1;
    if (['orders', 'history', 'invoices'].contains(section)) return 2;
    if (['profile', 'vehicles'].contains(section)) return 3;
  }
  if (role == 'technician') {
    if (['jobs', 'orders'].contains(section)) return 1;
    if (section == 'history') return 2;
    if (section == 'profile') return 3;
  }
  return null;
}

void showUnavailable(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Belum tersedia — fitur direncanakan pada fase berikutnya.',
        ),
      ),
    );
