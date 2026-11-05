import 'package:bengkel_kendaraan/core/data/firebase_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
