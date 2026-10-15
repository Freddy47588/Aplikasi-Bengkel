import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';

class LogoutButton extends ConsumerStatefulWidget {
  const LogoutButton({super.key, this.icon = false});
  final bool icon;
  @override
  ConsumerState<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<LogoutButton> {
  bool busy = false;
  Future<void> logout() async {
    setState(() => busy = true);
    try {
      await ref.read(authSessionProvider.notifier).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authError(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    return widget.icon
        ? IconButton(
            tooltip: 'Keluar',
            onPressed: busy ? null : logout,
            icon: busy ? progress : const Icon(Icons.logout),
          )
        : FilledButton(
            onPressed: busy ? null : logout,
            child: busy ? progress : const Text('Keluar'),
          );
  }
}
