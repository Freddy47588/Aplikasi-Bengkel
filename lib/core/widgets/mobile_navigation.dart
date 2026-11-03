import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileNavigation extends StatelessWidget {
  const MobileNavigation({super.key, required this.role});
  final String role;
  @override
  Widget build(BuildContext context) {
    final destinations = role == 'admin'
        ? [
            ('home', 'Beranda', Icons.home),
            ('bookings', 'Booking', Icons.event),
            ('technicians', 'Bengkel', Icons.garage_outlined),
            ('profile', 'Profil', Icons.person),
          ]
        : [
            ('home', 'Beranda', Icons.home),
            (
              role == 'customer' ? 'booking' : 'jobs',
              role == 'customer' ? 'Booking' : 'Pekerjaan',
              Icons.event,
            ),
            (
              'history',
              role == 'customer' ? 'Servis' : 'Riwayat',
              Icons.history,
            ),
            ('profile', 'Profil', Icons.person),
          ];
    final path = GoRouterState.of(context).uri.path;
    final index =
        navigationIndex(role, path) ??
        destinations.indexWhere(
          (d) => path == '/$role/${d.$1}' || path.startsWith('/$role/${d.$1}/'),
        );
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (i) => context.go('/$role/${destinations[i].$1}'),
      destinations: destinations
          .map((d) => NavigationDestination(icon: Icon(d.$3), label: d.$2))
          .toList(),
    );
  }
}

/// Auxiliary routes belong to the same visible product area as their parent.
int? navigationIndex(String role, String path) {
  final section = path
      .split('/')
      .where((s) => s.isNotEmpty)
      .skip(1)
      .firstOrNull;
  if (role == 'admin' &&
      ['orders', 'inventory', 'invoices', 'history'].contains(section)) {
    return 2;
  }
  if (role == 'customer') {
    if (section == 'bookings') return 1;
    if (['orders', 'invoices'].contains(section)) return 2;
    if (section == 'vehicles') return 3;
  }
  if (role == 'technician' && section == 'orders') return 1;
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
