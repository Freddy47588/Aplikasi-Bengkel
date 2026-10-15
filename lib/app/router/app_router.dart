import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/user_role.dart';
import '../../features/auth/data/auth_repository.dart';
export '../../features/auth/data/auth_repository.dart';
import '../../features/customer/presentation/vehicles_screen.dart';
import '../../core/widgets/foundation_pages.dart';
import '../../features/customer/presentation/service_history_screen.dart';
import '../../features/admin/presentation/admin_bookings_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/presentation/customer_booking_screen.dart';
import '../../features/customer/presentation/customer_dashboard_screen.dart';
import '../../features/technician/presentation/technician_dashboard_screen.dart';
import '../../features/technician/presentation/technician_jobs_screen.dart';
import '../../features/technician/presentation/service_orders_screen.dart';
import '../../features/technician/presentation/technicians_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authSessionProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    refreshListenable: refresh,
    initialLocation: '/login',
    redirect: (context, state) =>
        sessionRedirect(ref.read(authSessionProvider), state.uri.path),
    errorBuilder: (context, state) => const FoundationPage(
      title: 'Halaman tidak ditemukan',
      description: 'Gunakan navigasi untuk kembali ke halaman utama.',
    ),
    routes: [
      GoRoute(
        path: '/admin/inventory',
        builder: (_, _) => const InventoryScreen(),
      ),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(
        path: '/customer/vehicles',
        builder: (_, _) => const VehiclesScreen(),
      ),
      for (final role in UserRole.values) ...[
        GoRoute(
          path: '/${role.name}/orders',
          builder: (_, _) => const ServiceOrdersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  ServiceOrderDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/${role.name}/profile',
          builder: (_, _) => FoundationPage(
            title: 'Profil ${role.label}',
            description:
                'Akun ${role.label}. Identitas dan akses dikelola Firebase.',
          ),
        ),
        GoRoute(
          path: '/${role.name}/history',
          builder: (_, _) => const ServiceHistoryScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  ServiceHistoryDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
      GoRoute(
        path: '/admin/technicians',
        builder: (_, _) => const TechniciansScreen(),
      ),
      GoRoute(
        path: '/customer/bookings',
        builder: (_, _) => const BookingListPage(customer: true),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                BookingDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/customer',
        redirect: (context, state) => '/customer/home',
      ),
      GoRoute(
        path: '/customer/home',
        builder: (context, state) => const CustomerDashboardScreen(),
      ),
      GoRoute(
        path: '/customer/booking',
        builder: (context, state) => const CustomerBookingScreen(),
      ),
      GoRoute(
        path: '/technician',
        redirect: (context, state) => '/technician/home',
      ),
      GoRoute(
        path: '/technician/home',
        builder: (context, state) => const TechnicianDashboardScreen(),
      ),
      GoRoute(
        path: '/technician/jobs',
        builder: (context, state) => const TechnicianJobsScreen(),
      ),
      GoRoute(path: '/admin', redirect: (context, state) => '/admin/home'),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/bookings',
        builder: (context, state) => const AdminBookingsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                BookingDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String? sessionRedirect(AuthSession session, String path) {
  if (session.loading) return path == '/account' ? null : '/account';
  if (session.uid == null) return path == '/login' ? null : '/login';
  if (!session.isAuthenticated) return path == '/account' ? null : '/account';
  final home = '/${session.role!.name}/home';
  if (path == '/login' ||
      path == '/account' ||
      path == '/' ||
      path == '/${session.role!.name}') {
    return home;
  }
  if (!path.startsWith('/${session.role!.name}/')) return home;
  return null;
}
