import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/widgets/logout_button.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/status_chip.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:bengkel_kendaraan/features/auth/data/auth_repository.dart';
import 'package:bengkel_kendaraan/features/auth/presentation/account_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  bool busy = false;
  String? message;

  Future<void> run(Future<void> Function() action, [String? success]) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      if (mounted && success != null) setState(() => message = success);
    } catch (e) {
      if (mounted) setState(() => message = authError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final role = session.role;
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final repo = ref.read(authRepositoryProvider);
    final email = session.email ?? 'Pengguna BengkelKu';
    final verification = StatusChip(
      label: session.verified ? 'Email Terverifikasi' : 'Belum Terverifikasi',
      tone: session.verified
          ? StatusChipTone.success
          : StatusChipTone.warning,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Akun'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/${role.name}/home'),
        ),
      ),
      bottomNavigationBar: MobileNavigation(role: role.name),
      body: WorkshopBody(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            AccountProfileHeader(
              label: 'Akun ${role.label}',
              email: email,
              badge: verification,
            ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informasi Akun',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _ProfileRow(
                      icon: Icons.badge_outlined,
                      label: 'Peran Sistem',
                      value: 'Peran: ${role.label}',
                    ),
                    const Divider(height: 22),
                    _ProfileRow(
                      icon: Icons.alternate_email_rounded,
                      label: 'Email Terdaftar',
                      value: email,
                    ),
                    const Divider(height: 22),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset_rounded),
                      title: const Text('Ubah Password'),
                      subtitle: const Text(
                        'Kirim tautan pembaruan kata sandi ke email akun Anda.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: busy || session.email == null
                          ? null
                          : () => run(
                                () => repo.resetPassword(session.email!),
                                'Tautan ubah password dikirim ke ${session.email}.',
                              ),
                    ),
                    const Divider(height: 22),
                    Text(
                      'Verifikasi Email',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.verified
                          ? 'Email akun sudah terverifikasi.'
                          : 'Buka tautan verifikasi pada email lalu muat ulang status akun.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        if (!session.verified)
                          FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () => run(
                                      repo.sendVerification,
                                      'Email verifikasi dikirim.',
                                    ),
                            icon: const Icon(Icons.mark_email_read_outlined),
                            label: const Text('Kirim Verifikasi'),
                          ),
                        OutlinedButton(
                          onPressed: busy ? null : () => run(repo.refresh),
                          child: const Text('Periksa ulang status akun'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentBorder),
                  ),
                  child: Text(
                    message!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (role.name == 'customer') ...[
              const SizedBox(height: 16),
              Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Garasi & dokumen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.directions_car_outlined),
                        title: const Text('Kendaraan Saya'),
                        subtitle:
                            const Text('Kelola daftar motor dan mobil Anda'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/customer/vehicles'),
                      ),
                      const Divider(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('Invoice Saya'),
                        subtitle: const Text('Riwayat pembayaran dan nota PDF'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/customer/invoices'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const LogoutButton(outlined: true, label: 'Keluar Akun'),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
