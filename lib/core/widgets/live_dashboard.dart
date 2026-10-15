import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../data/booking_repository.dart';
import '../data/vehicle_repository.dart';
import '../models/booking.dart';
import 'foundation_pages.dart';
import 'mobile_navigation.dart';
import 'logout_button.dart';

class LiveDashboard extends ConsumerWidget {
  const LiveDashboard({super.key, required this.customer});
  final bool customer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final role = customer ? 'customer' : 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Text(customer ? 'BengkelKu • Pelanggan' : 'Dashboard Bengkel'),
        actions: [const LogoutButton(icon: true)],
      ),
      bottomNavigationBar: MobileNavigation(role: role),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  ref.watch(authSessionProvider).email ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                bookings.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) =>
                      const Text('Statistik booking belum dapat dimuat.'),
                  data: (items) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Dari ${items.length} booking terbaru (maks. 100)\n'
                        'Menunggu: ${items.where((b) => b.status == BookingStatus.pending).length}\n'
                        'Dikonfirmasi: ${items.where((b) => b.status == BookingStatus.confirmed).length}',
                      ),
                    ),
                  ),
                ),
                if (customer)
                  ref
                      .watch(vehiclesProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) =>
                            const Text('Jumlah kendaraan belum dapat dimuat.'),
                        data: (v) =>
                            Text('${v.length} kendaraan aktif (maks. 50)'),
                      ),
                const SizedBox(height: 16),
                if (customer) ...[
                  FilledButton.icon(
                    onPressed: () => context.go('/customer/booking'),
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Booking Servis'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/customer/vehicles'),
                    icon: const Icon(Icons.directions_car),
                    label: const Text('Kendaraan Saya'),
                  ),
                ] else
                  FilledButton(
                    onPressed: () => context.go('/admin/bookings'),
                    child: const Text('Kelola Booking'),
                  ),
                OutlinedButton(
                  onPressed: () => context.go('/$role/orders'),
                  child: const Text('Service Order dan progres servis'),
                ),
                if (!customer)
                  OutlinedButton(
                    onPressed: () => context.go('/admin/inventory'),
                    child: const Text('Inventori dan stok minimum'),
                  ),
                OutlinedButton(
                  onPressed: () => context.go('/$role/history'),
                  child: const Text('Riwayat'),
                ),
                const SizedBox(height: 24),
                Text(
                  customer ? 'Booking Saya' : 'Booking Pelanggan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                BookingListContent(customer: customer),
                const SizedBox(height: 24),
                const Text(
                  'Riwayat servis, pembayaran dan laporan tersedia pada fase berikutnya.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
