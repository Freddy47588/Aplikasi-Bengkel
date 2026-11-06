import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../../core/widgets/workshop_ui.dart';
import 'account_ui.dart';

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
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      if (reset) {
        await repo.resetPassword(email.text);
        if (mounted) {
          setState(
            () => message =
                'Jika email terdaftar, tautan reset akan dikirim. Periksa inbox dan spam.',
          );
        }
      } else if (register) {
        await repo.register(email.text, password.text);
      } else {
        await repo.login(email.text, password.text);
      }
    } catch (e) {
      if (mounted) setState(() => message = authError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void leaveRecovery() => setState(() {
    resetMode = false;
    message = null;
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !resetMode,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && resetMode && !busy) leaveRecovery();
    },
    child: Scaffold(
      appBar: AppBar(
        backgroundColor: resetMode ? Colors.white : null,
        leading: resetMode
            ? IconButton(
                tooltip: 'Kembali ke Login',
                onPressed: busy ? null : leaveRecovery,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: WorkshopBody(
        showWave: true,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                if (resetMode)
                  const AccountIntro(
                    art: WorkshopArt.password,
                    title: 'Lupa Password?',
                    description:
                        'Masukkan email akun Anda untuk menerima tautan pengaturan ulang password.',
                  )
                else ...[
                  const BrandLockup(),
                  const SizedBox(height: 16),
                  Text(
                    register ? 'Buat Akun Baru' : 'Masuk ke Akun Anda',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    register
                        ? 'Daftar untuk mengelola kendaraan dan booking servis.'
                        : 'Silakan masuk untuk melanjutkan.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: (v) =>
                            RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v?.trim() ?? '')
                            ? null
                            : resetMode
                            ? 'Isi email yang valid untuk reset kata sandi.'
                            : 'Email tidak valid.',
                      ),
                      const SizedBox(height: 16),
                      if (!resetMode)
                        TextFormField(
                          controller: password,
                          enabled: !busy,
                          obscureText: obscure,
                          autofillHints: [
                            register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline),
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
                          validator: (v) =>
                              (v?.length ?? 0) < (register ? 8 : 1)
                              ? (register
                                    ? 'Minimal 8 karakter.'
                                    : 'Isi kata sandi.')
                              : null,
                        ),
                      if (!register && !resetMode)
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
                      const SizedBox(height: 20),
                      if (message != null)
                        Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              message!,
                              key: const Key('auth-message'),
                            ),
                          ),
                        ),
                      if (busy)
                        const Center(child: CircularProgressIndicator()),
                      if (resetMode)
                        FilledButton.icon(
                          onPressed: busy ? null : () => submit(reset: true),
                          icon: const Icon(Icons.send_outlined),
                          label: const Text('Kirim Tautan'),
                        )
                      else
                        FilledButton(
                          onPressed: busy
                              ? null
                              : () => submit(reset: resetMode),
                          child: Text(
                            resetMode
                                ? 'Kirim Tautan'
                                : register
                                ? 'Daftar'
                                : 'Masuk dengan Email',
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (resetMode)
                        TextButton(
                          onPressed: busy ? null : leaveRecovery,
                          child: const Text('Kembali ke Login'),
                        )
                      else
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  if (resetMode) {
                                    resetMode = false;
                                  } else {
                                    register = !register;
                                  }
                                  message = null;
                                }),
                          child: Text(
                            resetMode
                                ? 'Kembali ke Login'
                                : register
                                ? 'Sudah punya akun? Masuk'
                                : 'Daftar akun pelanggan',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
    if (state == AppLifecycleState.resumed && !busy) {
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
      if (mounted) setState(() => message = success);
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: verification ? null : const Text('Status Akun'),
      ),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          children: [
            AccountIntro(
              art: verification ? WorkshopArt.verification : WorkshopArt.lock,
              title: verification ? 'Verifikasi Email' : 'Status akun Anda',
              description: verification
                  ? 'Verifikasi alamat email akun Anda untuk melanjutkan ke BengkelKu.'
                  : 'Periksa status akun untuk melanjutkan ke BengkelKu.',
            ),
            const SizedBox(height: 24),
            if (s.loading || busy)
              const Center(child: CircularProgressIndicator()),
            if (s.email != null)
              SelectableText(s.email!, textAlign: TextAlign.center),
            if (s.error != null)
              Semantics(liveRegion: true, child: Text(s.error!)),
            if (s.uid != null && !s.loading) ...[
              if (!s.active && s.role != null)
                const Text('Akun dinonaktifkan. Hubungi pengelola bengkel.'),
              if (!s.verified && s.role != null && s.active) ...[
                const SizedBox(height: 20),
                const AccountNotice(
                  title: 'Periksa Kotak Masuk',
                  description:
                      'Buka tautan verifikasi pada email BengkelKu. Periksa juga folder spam.',
                ),
                const SizedBox(height: 12),
                const AccountNotice(
                  title: 'Tidak menerima email?',
                  description: 'Kirim ulang tautan, lalu periksa status akun.',
                  icon: Icons.info_outline,
                  tinted: true,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => run(
                          repo.sendVerification,
                          'Email verifikasi dikirim.',
                        ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kirim Ulang'),
                ),
                const SizedBox(height: 12),
              ],
              if (s.role == null)
                OutlinedButton(
                  onPressed: busy ? null : () => run(repo.completeProfile),
                  child: const Text('Lengkapi profil pelanggan'),
                ),
              OutlinedButton(
                onPressed: busy ? null : () => run(repo.refresh),
                child: const Text('Periksa ulang status akun'),
              ),
            ],
            if (message != null)
              Semantics(liveRegion: true, child: Text(message!)),
            TextButton(
              onPressed: busy ? null : () => run(repo.signOut),
              child: const Text('Keluar'),
            ),
          ],
        ),
      ),
    );
  }
}
