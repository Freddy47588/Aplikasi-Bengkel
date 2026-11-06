import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';
import 'account_ui.dart';

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
      if (mounted) setState(() => message = success);
    } catch (e) {
      if (mounted) setState(() => message = authError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!;
    final repo = ref.read(authRepositoryProvider);
    final largeText =
        MediaQuery.textScalerOf(context).scale(1) > 1.1 ||
        MediaQuery.sizeOf(context).width < 380;
    final verification = StatusChip(
      label: session.verified ? 'Terverifikasi' : 'Belum terverifikasi',
      tone: session.verified ? StatusChipTone.success : StatusChipTone.warning,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profil Saya'),
        leading: IconButton(
          tooltip: 'Kembali ke dashboard',
          onPressed: () => context.go('/${role.name}/home'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      bottomNavigationBar: MobileNavigation(role: role.name),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          children: [
            AccountProfileHeader(
              label: 'Akun ${role.label}',
              email: session.email ?? 'Email tidak tersedia',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.blueBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        ExpansionTile(
                          title: const Text('Informasi Akun'),
                          leading: const Icon(Icons.person_outline),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            SelectableText(
                              session.email ?? 'Email tidak tersedia',
                            ),
                            const SizedBox(height: 8),
                            Text('Peran: ${role.label}'),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: StatusChip(
                                label: session.active
                                    ? 'Akun aktif'
                                    : 'Akun nonaktif',
                                tone: session.active
                                    ? StatusChipTone.success
                                    : StatusChipTone.danger,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Perubahan peran atau status aktif dikelola pengelola bengkel.',
                            ),
                          ],
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: const Icon(Icons.key_outlined),
                          title: Text(busy ? 'Memproses…' : 'Ubah Password'),
                          subtitle: const Text('Tautan reset melalui email'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: busy || session.email == null
                              ? null
                              : () => run(
                                  () => repo.resetPassword(session.email!),
                                  'Jika email terdaftar, tautan reset akan dikirim. Periksa inbox dan spam.',
                                ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ExpansionTile(
                          title: const Text('Verifikasi Email'),
                          leading: const Icon(Icons.mail_outline),
                          subtitle: largeText ? verification : null,
                          trailing: largeText
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    verification,
                                    const SizedBox(width: 4),
                                    const Icon(Icons.expand_more),
                                  ],
                                ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          expandedCrossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              session.verified
                                  ? 'Alamat email akun ini sudah terverifikasi.'
                                  : 'Verifikasi email diperlukan untuk mengakses akun.',
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
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(liveRegion: true, child: Text(message!)),
                    ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (role.name == 'customer') ...[
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.blueBorder),
                      ),
                      child: ExpansionTile(
                        title: const Text('Garasi & dokumen'),
                        leading: const Icon(Icons.folder_outlined),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.directions_car_outlined),
                            title: const Text('Kendaraan Saya'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/customer/vehicles'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: const Text('Invoice Saya'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.go('/customer/invoices'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const LogoutButton(outlined: true, label: 'Keluar Akun'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
