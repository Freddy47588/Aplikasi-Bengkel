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
            ('technicians', 'Teknisi', Icons.engineering),
            ('profile', 'Profil', Icons.person),
          ]
        : [
            ('home', 'Beranda', Icons.home),
            (
              role == 'customer' ? 'booking' : 'jobs',
              role == 'customer' ? 'Booking' : 'Pekerjaan',
              Icons.event,
            ),
            ('history', 'Riwayat', Icons.history),
            ('profile', 'Profil', Icons.person),
          ];
    final path = GoRouterState.of(context).uri.path;
    final index =
        role == 'customer' &&
            (path == '/customer/bookings' ||
                path.startsWith('/customer/bookings/'))
        ? 2
        : destinations.indexWhere(
            (d) =>
                path == '/$role/${d.$1}' || path.startsWith('/$role/${d.$1}/'),
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

void showUnavailable(BuildContext context) =>
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Belum tersedia — fitur direncanakan pada fase berikutnya.',
        ),
      ),
    );
