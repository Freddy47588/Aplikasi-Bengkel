import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/user_role.dart';
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
  final authSession = ref.watch(authSessionProvider);
  final currentRole = authSession.role;

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';

      if (!authSession.isAuthenticated) {
        return isLoginRoute ? null : '/login';
      }

      if (isLoginRoute) {
        switch (currentRole) {
          case UserRole.customer:
            return '/customer/home';
          case UserRole.technician:
            return '/technician/home';
          case UserRole.admin:
            return '/admin/home';
          case null:
            return '/login';
        }
      }

      if (currentRole == UserRole.customer &&
          (location.startsWith('/technician') ||
              location.startsWith('/admin'))) {
        return '/customer/home';
      }

      if (currentRole == UserRole.technician &&
          (location.startsWith('/customer') || location.startsWith('/admin'))) {
        return '/technician/home';
      }

      if (currentRole == UserRole.admin &&
          (location.startsWith('/customer') ||
              location.startsWith('/technician'))) {
        return '/admin/home';
      }

      return null;
    },
    routes: [
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
});
