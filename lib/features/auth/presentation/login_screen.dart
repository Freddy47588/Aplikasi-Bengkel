import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/widgets/logout_button.dart';
import 'package:bengkel_kendaraan/core/widgets/session_splash.dart';
import 'package:bengkel_kendaraan/features/auth/data/auth_repository.dart';
import 'package:bengkel_kendaraan/features/auth/presentation/account_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool resetMode = false;
  bool busy = false;
  bool obscure = true;
  String? message;
  bool messageSuccess = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      message = null;
      messageSuccess = false;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (reset) {
        await repo.resetPassword(email.text);
        if (mounted) {
          setState(() {
            messageSuccess = true;
            message =
                'Jika email terdaftar, tautan reset kata sandi telah dikirim.';
          });
        }
      } else if (register) {
        await repo.register(email.text, password.text);
      } else {
        await repo.login(email.text, password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          messageSuccess = false;
          message = authError(e);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String get _title {
    if (resetMode) return 'Reset Kata Sandi';
    if (register) return 'Daftar Akun Pelanggan';
    return 'Masuk ke Akun Anda';
  }

  String get _subtitle {
    if (resetMode) {
      return 'Masukkan email akun BengkelKu Anda untuk menerima tautan pemulihan.';
    }
    if (register) {
      return 'Buat akun pelanggan untuk booking servis, pantau progres, dan lihat invoice digital.';
    }
    return 'Kelola jadwal booking, progres pengerjaan kendaraan, stok suku cadang, dan pembayaran.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && (register || resetMode)) {
          setState(() {
            register = false;
            resetMode = false;
            message = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccountIntro(
                      title: _title,
                      description: _subtitle,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: email,
                              enabled: !busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: resetMode
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'nama@bengkelku.id',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (resetMode) {
                                  if (value.isEmpty ||
                                      !value.contains('@') ||
                                      !value.split('@').last.contains('.')) {
                                    return 'Isi email yang valid untuk reset kata sandi.';
                                  }
                                  return null;
                                }
                                if (value.isEmpty || !value.contains('@')) {
                                  return 'Email tidak valid.';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (resetMode) {
                                  submit(reset: true);
                                }
                              },
                            ),
                            if (!resetMode) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: password,
                                enabled: !busy,
                                obscureText: obscure,
                                textInputAction: TextInputAction.done,
                                autofillHints: [
                                  register
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: obscure
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi',
                                    onPressed: () =>
                                        setState(() => obscure = !obscure),
                                    icon: Icon(
                                      obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').length < 6) {
                                    return 'Kata sandi minimal 6 karakter';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => submit(),
                              ),
                            ],
                            if (!register && !resetMode) ...[
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => setState(() {
                                            resetMode = true;
                                            message = null;
                                          }),
                                  child: const Text('Lupa kata sandi'),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 16),
                            if (message != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: messageSuccess
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: messageSuccess
                                        ? AppColors.success
                                            .withValues(alpha: 0.3)
                                        : AppColors.danger
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    message!,
                                    key: const Key('auth-message'),
                                    style: TextStyle(
                                      color: messageSuccess
                                          ? AppColors.success
                                          : AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (resetMode)
                              FilledButton.icon(
                                onPressed:
                                    busy ? null : () => submit(reset: true),
                                icon: busy
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: const Text('Kirim Tautan'),
                              )
                            else
                              FilledButton(
                                onPressed: busy ? null : () => submit(),
                                child: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        register
                                            ? 'Daftar'
                                            : 'Masuk dengan Email',
                                      ),
                              ),
                            const SizedBox(height: 12),
                            if (resetMode)
                              OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                          resetMode = false;
                                          message = null;
                                        }),
                                child: const Text('Kembali ke Login'),
                              )
                            else
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => setState(() {
                                          register = !register;
                                          message = null;
                                        }),
                                child: Text(
                                  register
                                      ? 'Sudah punya akun? Masuk'
                                      : 'Daftar akun pelanggan',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AccountNotice(
                      icon: Icons.verified_user_outlined,
                      title: 'Akses sesuai peran bengkel',
                      description:
                          'Peran Admin dan Teknisi diatur oleh pengelola bengkel; pendaftar baru otomatis menjadi akun Pelanggan.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountState();
}

class _AccountState extends ConsumerState<AccountScreen>
    with WidgetsBindingObserver {
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      run(() => ref.read(authRepositoryProvider).refresh());
    }
  }

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
    final s = ref.watch(authSessionProvider);
    final repo = ref.read(authRepositoryProvider);
    if (s.loading) return const SessionSplash();
    final verification = s.role != null && !s.verified && s.active;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccountIntro(
                    title: verification
                        ? 'Verifikasi Email Anda'
                        : !s.active
                            ? 'Akses Akun Dinonaktifkan'
                            : 'Menyiapkan Profil Akun',
                    description: verification
                        ? 'Kami perlu memastikan email ${s.email ?? '-'} aktif sebelum membuka dashboard ${s.role?.label ?? 'BengkelKu'}.'
                        : !s.active
                            ? 'Akun dinonaktifkan. Hubungi pengelola bengkel.'
                            : 'Data profil Anda belum lengkap. Tekan muat ulang atau lengkapi profil.',
                  ),
                  const SizedBox(height: 18),
                  if (!s.active && s.role != null)
                    const AccountNotice(
                      icon: Icons.block_rounded,
                      title: 'Akun Nonaktif',
                      description:
                          'Akses dashboard ditutup sementara hingga akun diaktifkan kembali oleh admin.',
                      tinted: true,
                    ),
                  if (!s.verified && s.role != null && s.active) ...[
                    const AccountNotice(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Email belum terverifikasi',
                      description:
                          'Buka tautan verifikasi di kotak masuk atau folder spam email Anda, lalu periksa ulang status akun.',
                      tinted: true,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () => run(
                                repo.sendVerification,
                                'Email verifikasi dikirim ke ${s.email ?? 'alamat Anda'}.',
                              ),
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('Kirim Ulang'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (s.role == null) ...[
                    OutlinedButton(
                      onPressed: busy ? null : () => run(repo.completeProfile),
                      child: const Text('Lengkapi Profil'),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton(
                    onPressed: busy ? null : () => run(repo.refresh),
                    child: const Text('Periksa ulang status akun'),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 16),
                  const LogoutButton(outlined: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
