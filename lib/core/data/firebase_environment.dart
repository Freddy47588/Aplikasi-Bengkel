import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseEnvironment {
  const FirebaseEnvironment({
    this.emulator = const bool.fromEnvironment('USE_FIREBASE_EMULATOR'),
    this.host = const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
      defaultValue: '127.0.0.1',
    ),
    this.authPort = const int.fromEnvironment(
      'FIREBASE_AUTH_PORT',
      defaultValue: 9099,
    ),
    this.firestorePort = const int.fromEnvironment(
      'FIRESTORE_PORT',
      defaultValue: 8080,
    ),
  });

  final bool emulator;
  final String host;
  final int authPort, firestorePort;

  static FirebaseApp get app => const FirebaseEnvironment().emulator
      ? Firebase.app('bengkelku-emulator')
      : Firebase.app();

  void validate({required bool debug}) {
    if (!emulator) return;
    if (!debug ||
        !['127.0.0.1', 'localhost', '10.0.2.2'].contains(host) ||
        authPort < 1 ||
        authPort > 65535 ||
        firestorePort < 1 ||
        firestorePort > 65535) {
      throw StateError('Konfigurasi emulator hanya untuk debug lokal.');
    }
  }

  Future<void> initialize() async {
    validate(debug: kDebugMode);
    final app = emulator
        ? await Firebase.initializeApp(
            name: 'bengkelku-emulator',
            demoProjectId: 'demo-bengkelku',
          )
        : await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
    if (emulator) {
      await FirebaseAuth.instanceFor(app: app).useAuthEmulator(host, authPort);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      firestore.settings = const Settings(persistenceEnabled: false);
      firestore.useFirestoreEmulator(host, firestorePort);
    }
  }
}
