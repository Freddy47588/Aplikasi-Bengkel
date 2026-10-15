import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

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
  bool busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool reset = false}) async {
    if (reset) {
      if (!email.text.trim().contains('@')) {
        setState(
          () => message = 'Isi email yang valid untuk reset kata sandi.',
        );
        return;
      }
    } else if (!form.currentState!.validate()) {
      return;
    }
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BengkelKu')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                register ? 'Daftar Pelanggan' : 'Masuk',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Email tidak valid.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      autofillHints: [
                        register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                      ),
                      validator: (v) => (v?.length ?? 0) < (register ? 8 : 1)
                          ? (register
                                ? 'Minimal 8 karakter.'
                                : 'Isi kata sandi.')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    if (message != null)
                      Text(message!, key: const Key('auth-message')),
                    if (busy) const Center(child: CircularProgressIndicator()),
                    FilledButton(
                      onPressed: busy ? null : submit,
                      child: Text(register ? 'Daftar' : 'Masuk dengan Email'),
                    ),
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
                    TextButton(
                      onPressed: busy ? null : () => submit(reset: true),
                      child: const Text('Lupa kata sandi'),
                    ),
                  ],
                ),
              ),
            ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Status Akun')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (s.loading || busy)
              const Center(child: CircularProgressIndicator()),
            Text(s.email ?? 'Memuat sesi...'),
            if (s.error != null) Text(s.error!),
            if (s.uid != null && !s.loading) ...[
              if (!s.active && s.role != null)
                const Text('Akun dinonaktifkan. Hubungi pengelola bengkel.'),
              if (!s.verified && s.role != null && s.active) ...[
                const Text(
                  'Verifikasi email untuk mengakses kendaraan dan booking. Periksa inbox dan spam.',
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => run(
                          repo.sendVerification,
                          'Email verifikasi dikirim.',
                        ),
                  child: const Text('Kirim ulang verifikasi'),
                ),
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
            if (message != null) Text(message!),
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
