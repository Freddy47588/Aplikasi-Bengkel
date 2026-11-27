import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/features/customer/presentation/vehicles_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture, viewport, fixtureDatabase;

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
    final roboto = FontLoader('Roboto');
    for (final name in [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Black.ttf',
    ]) {
      roboto.addFont(
        File.fromUri(
          fonts.resolve(name),
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await roboto.load();
    await (FontLoader('MaterialIcons')..addFont(
          File.fromUri(
            fonts.resolve('MaterialIcons-Regular.otf'),
          ).readAsBytes().then(ByteData.sublistView),
        ))
        .load();
  });

  testWidgets(
    'legacy vehicle requires an explicit kind; delete removes vehicle permanently',
    (tester) async {
      viewport(tester, 320);
      final db = FakeFirebaseFirestore();
      await db.doc('vehicles/legacy').set({
        'ownerId': 'customer-demo',
        'name': 'Honda Lama',
        'plate': 'B 1234 QA',
        'active': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.customer);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      container.read(appRouterProvider).go('/customer/vehicles');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Honda Lama'));
      await tester.tap(find.text('Honda Lama'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SegmentedButton>(
              find.byWidgetPredicate((widget) => widget is SegmentedButton),
            )
            .selected,
        isEmpty,
      );
      await reveal(tester, find.text('Simpan Kendaraan'));
      await tester.tap(find.text('Simpan Kendaraan'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih jenis kendaraan.'), findsOneWidget);
      expect(
        (await db.doc('vehicles/legacy').get()).data()!.containsKey('kind'),
        false,
      );
      await reveal(tester, find.text('Motor'));
      await tester.tap(find.text('Motor'));
      await tester.enterText(find.byKey(const Key('vehicle-notes')), 'Hitam');
      await reveal(tester, find.text('Simpan Kendaraan'));
      await tester.tap(find.text('Simpan Kendaraan'));
      await tester.pumpAndSettle();
      expect((await db.doc('vehicles/legacy').get())['kind'], 'motorcycle');
      await reveal(tester, find.text('Honda Lama'));
      await tester.tap(find.text('Honda Lama'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Hapus kendaraan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Honda Lama'), findsNothing);
      expect((await db.doc('vehicles/legacy').get()).exists, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'customer pages and full vehicle form reflow with keyboard and 200 percent text',
    (tester) async {
      viewport(tester, 390);
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      final db = await fixtureDatabase();
      for (final row in [
        ('mockup-motor', 'Honda Vario 160', 'B 4123 KZU', 'motorcycle', true),
        ('mockup-car', 'Toyota Avanza', 'B 1789 FDG', 'car', true),
        ('mockup-archived', 'Yamaha NMAX', 'B 6677 TYL', 'motorcycle', false),
      ]) {
        await db.doc('vehicles/${row.$1}').set({
          'ownerId': 'customer-demo',
          'name': row.$2,
          'plate': row.$3,
          'kind': row.$4,
          'active': row.$5,
          'notes': '',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.customer);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundary, child: const BengkelKuApp()),
        ),
      );
      final router = container.read(appRouterProvider);
      router.go('/customer/home');
      await tester.pumpAndSettle();
      await captureFixture(tester, boundary, 'customer-home-current');
      router.go('/customer/vehicles');
      await tester.pumpAndSettle();
      await captureFixture(tester, boundary, 'customer-vehicles-current');
      await tester.tap(find.text('Tambah kendaraan'));
      await tester.pumpAndSettle();
      await captureFixture(tester, boundary, 'customer-vehicle-form-current');
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Honda Vario 160'));
      await tester.pumpAndSettle();
      await captureFixture(tester, boundary, 'customer-vehicle-edit-current');
      await tester.enterText(find.byKey(const Key('vehicle-name')), '');
      await tester.enterText(find.byKey(const Key('vehicle-plate')), '');
      for (final width in [320.0, 360.0, 390.0, 430.0, 800.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final keyboard in [0.0, 280.0]) {
            tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(find.text('Simpan Kendaraan')).bottom,
              lessThanOrEqualTo(740 - keyboard),
              reason: 'save remains above keyboard',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$width/$scale/keyboard=$keyboard',
            );
            await reveal(tester, find.text('Simpan Kendaraan'));
            await tester.tap(find.text('Simpan Kendaraan'));
            await tester.pumpAndSettle();
            expect(find.text('Isi nama kendaraan.'), findsOneWidget);
            expect(find.text('Plat harus seperti B 1234 XYZ.'), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: '$width/$scale validation',
            );
          }
        }
      }
      tester.view.resetViewInsets();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpWidget(const SizedBox());
      expect(find.byType(VehicleFormScreen), findsNothing);
    },
  );
}
