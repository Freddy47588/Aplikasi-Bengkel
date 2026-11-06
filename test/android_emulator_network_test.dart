import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android debug permits emulator HTTP only for the explicit local hosts',
    () {
      final manifest = File(
        'android/app/src/debug/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        contains(
          'android:networkSecurityConfig="@xml/emulator_network_security"',
        ),
      );
      final config = File(
        'android/app/src/debug/res/xml/emulator_network_security.xml',
      ).readAsStringSync();
      expect(
        config,
        contains('<base-config cleartextTrafficPermitted="false"'),
      );
      final allowed = RegExp(
        r'<domain includeSubdomains="false">([^<]+)</domain>',
      ).allMatches(config).map((m) => m.group(1)).toSet();
      expect(allowed, {'127.0.0.1', 'localhost', '10.0.2.2'});
      expect(RegExp(r'<domain[\s>]').allMatches(config).length, allowed.length);
      expect(
        RegExp(r'cleartextTrafficPermitted="true"').allMatches(config).length,
        1,
      );
      expect(
        config,
        contains('<domain-config cleartextTrafficPermitted="true">'),
      );
    },
  );

  test(
    'emulator cleartext opt-in is absent from main and profile manifests',
    () {
      for (final variant in ['main', 'profile']) {
        final manifest = File(
          'android/app/src/$variant/AndroidManifest.xml',
        ).readAsStringSync();
        expect(manifest, isNot(contains('networkSecurityConfig')));
        expect(manifest, isNot(contains('usesCleartextTraffic="true"')));
        expect(
          File(
            'android/app/src/$variant/res/xml/emulator_network_security.xml',
          ).existsSync(),
          isFalse,
        );
      }
    },
  );
}
