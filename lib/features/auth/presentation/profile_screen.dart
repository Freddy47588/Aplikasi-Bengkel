import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<ProfileScreen> {
  bool busy = false;
  String? message;
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      bottomNavigationBar: MobileNavigation(role: session.role!.name),
      body: WorkshopBody(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WorkshopHero(
                  eyebrow: 'Akun ${session.role!.label}',
                  title: 'Profil Saya',
                  description: session.email ?? 'Akun BengkelKu',
                ),
                ContentSection(
                  title: 'Informasi akun',
                  children: [
                    const Text('Email'),
                    const SizedBox(height: 4),
                    SelectableText(session.email ?? 'Email tidak tersedia'),
                    const SizedBox(height: 16),
                    Text('Peran: ${session.role!.label}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          label: session.active
                              ? 'Akun aktif'
                              : 'Akun nonaktif',
                          tone: session.active
                              ? StatusChipTone.success
                              : StatusChipTone.danger,
                        ),
                        StatusChip(
                          label: session.verified
                              ? 'Email terverifikasi'
                              : 'Email belum terverifikasi',
                          tone: session.verified
                              ? StatusChipTone.success
                              : StatusChipTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
                if (session.role!.name == 'customer')
                  ContentSection(
                    title: 'Garasi & dokumen',
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.directions_car_outlined),
                        title: const Text('Kendaraan Saya'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/customer/vehicles'),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: const Text('Invoice Saya'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/customer/invoices'),
                      ),
                    ],
                  ),
                ContentSection(
                  title: 'Keamanan akun',
                  children: [
                    const WorkshopIllustration(WorkshopArt.lock, height: 96),
                    const Text(
                      'Perubahan peran atau status aktif dikelola pengelola bengkel.',
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy || session.email == null
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                                message = null;
                              });
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .resetPassword(session.email!);
                                if (mounted) {
                                  setState(
                                    () => message =
                                        'Tautan reset dikirim. Periksa inbox dan spam.',
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => message = authError(e));
                                }
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
                            },
                      icon: const Icon(Icons.lock_reset),
                      label: Text(busy ? 'Mengirim…' : 'Reset kata sandi'),
                    ),
                    if (message != null)
                      Semantics(liveRegion: true, child: Text(message!)),
                  ],
                ),
                const SizedBox(height: 16),
                const LogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
