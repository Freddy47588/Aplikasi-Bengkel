import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/user_role.dart';
import '../../core/widgets/foundation_pages.dart';
import '../../features/admin/presentation/admin_bookings_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/customer/presentation/customer_booking_screen.dart';
import '../../features/customer/presentation/customer_dashboard_screen.dart';
import '../../features/technician/presentation/technician_dashboard_screen.dart';
import '../../features/technician/presentation/technician_jobs_screen.dart';

class AuthSession {
  const AuthSession({this.role});

  final UserRole? role;

  String get userId => role == UserRole.customer
      ? 'customer-demo'
      : '${role?.name ?? 'guest'}-demo';

  bool get isAuthenticated => role != null;
}

class AuthSessionController extends Notifier<AuthSession> {
  @override
  AuthSession build() => const AuthSession();

  void signIn(UserRole role) {
    state = AuthSession(role: role);
  }

  void signOut() {
    state = const AuthSession();
  }
}

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession>(
      AuthSessionController.new,
    );

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
      for (final role in UserRole.values) ...[
        GoRoute(
          path: '/${role.name}/profile',
          builder: (_, _) => FoundationPage(
            title: 'Profil ${role.label}',
            description:
                'Sesi demo ${role.label}. Autentikasi produksi belum tersedia.',
          ),
        ),
        GoRoute(
          path: '/${role.name}/history',
          builder: (_, _) => role == UserRole.customer
              ? const BookingListPage(customer: true)
              : const FoundationPage(
                  title: 'Riwayat',
                  description:
                      'Riwayat servis masih demo; belum tersedia data riwayat produksi.',
                ),
        ),
      ],
      GoRoute(
        path: '/admin/technicians',
        builder: (_, _) => const TechnicianJobsScreen(),
      ),
      GoRoute(
        path: '/customer/bookings/:id',
        builder: (_, state) =>
            BookingDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin/bookings/:id',
        builder: (_, state) =>
            BookingDetailPage(id: state.pathParameters['id']!),
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
  if (!session.isAuthenticated) return path == '/login' ? null : '/login';
  final home = '/${session.role!.name}/home';
  if (path == '/login' || path == '/' || path == '/${session.role!.name}') {
    return home;
  }
  if (!path.startsWith('/${session.role!.name}/')) return home;
  return null;
}
