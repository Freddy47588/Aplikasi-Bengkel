import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/data/firebase_environment.dart';
import 'core/widgets/session_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: SessionSplash()));
  try {
    await const FirebaseEnvironment().initialize();
    runApp(const ProviderScope(child: BengkelKuApp()));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Firebase belum dapat diinisialisasi. Periksa konfigurasi platform dan koneksi.',
                    ),
                    FilledButton(
                      onPressed: main,
                      child: const Text('Coba lagi'),
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
