import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/data/service_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';
import 'ui_ux_polish_test.dart' show viewport;

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final configFile = File('.dart_tool/package_config.json');
    final config = jsonDecode(configFile.readAsStringSync()) as Map;
    final flutter = (config['packages'] as List).cast<Map>().firstWhere(
      (p) => p['name'] == 'flutter',
    );
    final root = configFile.absolute.uri.resolve(flutter['rootUri'] as String);
    final fonts = Uri.parse(
      '${root.toString().replaceFirst(RegExp(r'/$'), '')}/',
    ).resolve('../../bin/cache/artifacts/material_fonts/');
    for (final font in {
      'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'],
      'MaterialIcons': ['MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(font.key);
      for (final name in font.value) {
        loader.addFont(
          File.fromUri(
            fonts.resolve(name),
          ).readAsBytes().then(ByteData.sublistView),
        );
      }
      await loader.load();
    }
  });

  testWidgets(
    'empty service catalog explains next action and preserves input',
    (tester) async {
      viewport(tester, 390);
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      final db = FakeFirebaseFirestore();
      final parent = testContainer(database: db);
      final container = ProviderContainer(
        parent: parent,
        overrides: [
          firestoreProvider.overrideWithValue(db),
          servicesProvider.overrideWith(
            (ref) => Stream.value(<WorkshopService>[]),
          ),
        ],
      );
      addTearDown(() {
        container.dispose();
        parent.dispose();
      });
      testAuth(container).signIn(UserRole.customer);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: UncontrolledProviderScope(
            container: container,
            child: const BengkelKuApp(),
          ),
        ),
      );
      container.read(appRouterProvider).go('/customer/booking');
      await tester.pumpAndSettle();
      expect(
        find.text('Belum ada layanan aktif. Hubungi pengelola bengkel.'),
        findsOneWidget,
      );

      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_UI')) return;
        await tester.runAsync(() async {
          for (final img in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(img.image, boundary.currentContext!);
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory(
            const String.fromEnvironment(
              'CAPTURE_DIR',
              defaultValue: 'build/full-audit',
            ),
          )..createSync(recursive: true);
          File(
            '${directory.path}/fixture-$name.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('booking-empty-top');
      await reveal(tester, find.byType(TextFormField));
      await tester.enterText(
        find.byType(TextFormField),
        'Rem berbunyi saat berhenti',
      );
      await reveal(tester, find.text('Konfirmasi Booking'));
      await capture('booking-empty-submit');
      expect(find.text('Rem berbunyi saat berhenti'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
