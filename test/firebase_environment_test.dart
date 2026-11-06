import 'package:bengkel_kendaraan/core/data/firebase_environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordingAuth extends Fake implements FirebaseAuth {
  String? host;
  int? port;
  bool? mapsHost;
  @override
  Future<void> useAuthEmulator(
    String host,
    int port, {
    bool automaticHostMapping = true,
  }) async {
    this.host = host;
    this.port = port;
    mapsHost = automaticHostMapping;
  }
}

class RecordingFirestore extends Fake implements FirebaseFirestore {
  String? host;
  int? port;
  bool? mapsHost;
  Settings? configuredSettings;
  @override
  set settings(Settings value) => configuredSettings = value;
  @override
  void useFirestoreEmulator(
    String host,
    int port, {
    bool sslEnabled = false,
    bool automaticHostMapping = true,
  }) {
    this.host = host;
    this.port = port;
    mapsHost = automaticHostMapping;
  }
}

void main() {
  test(
    'physical USB and AVD preserve explicit emulator routing on both SDKs',
    () async {
      for (final host in ['127.0.0.1', 'localhost', '10.0.2.2']) {
        final auth = RecordingAuth();
        final firestore = RecordingFirestore();
        await FirebaseEnvironment(
          emulator: true,
          host: host,
          authPort: 9100,
          firestorePort: 8100,
        ).connectEmulators(auth, firestore);
        expect(
          auth.mapsHost,
          isFalse,
          reason: 'Auth must preserve USB reverse host $host',
        );
        expect(
          firestore.mapsHost,
          isFalse,
          reason: 'Firestore must preserve USB reverse host $host',
        );
        expect(auth.host, host);
        expect(auth.port, 9100);
        expect(firestore.host, host);
        expect(firestore.port, 8100);
        expect(firestore.configuredSettings?.persistenceEnabled, isFalse);
      }
    },
  );
  test('emulator mode rejects release, remote endpoints and invalid ports', () {
    const local = FirebaseEnvironment(emulator: true);
    expect(() => local.validate(debug: false), throwsStateError);
    for (final host in ['bengkelku-app-bebd9.firebaseapp.com', '192.168.1.4']) {
      expect(
        () => FirebaseEnvironment(
          emulator: true,
          host: host,
        ).validate(debug: true),
        throwsStateError,
      );
    }
    expect(
      () => const FirebaseEnvironment(
        emulator: true,
        authPort: 0,
      ).validate(debug: true),
      throwsStateError,
    );
    expect(() => local.validate(debug: true), returnsNormally);
    expect(
      () => const FirebaseEnvironment(emulator: false).validate(debug: false),
      returnsNormally,
    );
  });
}
