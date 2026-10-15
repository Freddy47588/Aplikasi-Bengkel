import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/widgets/app_primary_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0EA5E9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: SizedBox(
                      height: isDesktop ? 620 : null,
                      child: isDesktop
                          ? Row(
                              children: [
                                Expanded(child: _BrandPanel()),
                                Expanded(
                                  child: _LoginPanel(
                                    onLogin: (role) {
                                      ref
                                          .read(authSessionProvider.notifier)
                                          .signIn(role);
                                      context.go(switch (role) {
                                        UserRole.customer => '/customer/home',
                                        UserRole.technician =>
                                          '/technician/home',
                                        UserRole.admin => '/admin/home',
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          : _LoginPanel(
                              onLogin: (role) {
                                ref
                                    .read(authSessionProvider.notifier)
                                    .signIn(role);
                                context.go(switch (role) {
                                  UserRole.customer => '/customer/home',
                                  UserRole.technician => '/technician/home',
                                  UserRole.admin => '/admin/home',
                                });
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.build_circle_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'BengkelKu',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sistem Manajemen Bengkel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kelola servis kendaraan dengan mudah dan terintegrasi.',
            style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.onLogin});

  final void Function(UserRole role) onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mode Demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Masuk sebagai Pelanggan',
            icon: Icons.person_outline_rounded,
            onPressed: () => onLogin(UserRole.customer),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: 'Masuk sebagai Teknisi',
            icon: Icons.engineering_rounded,
            onPressed: () => onLogin(UserRole.technician),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(
            label: 'Masuk sebagai Admin',
            icon: Icons.admin_panel_settings_rounded,
            onPressed: () => onLogin(UserRole.admin),
          ),
        ],
      ),
    );
  }
}
