import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class BengkelKuApp extends ConsumerStatefulWidget {
  const BengkelKuApp({super.key});

  @override
  ConsumerState<BengkelKuApp> createState() => _BengkelKuAppState();
}

class _BengkelKuAppState extends ConsumerState<BengkelKuApp>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed &&
        ref.read(authSessionProvider).uid != null) {
      refreshSession();
    }
  }

  Future<void> refreshSession() async {
    try {
      await ref.read(authRepositoryProvider).refresh();
    } catch (_) {
      /* Keep cached session on network loss; backend rules still authorize all writes. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BengkelKu',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
