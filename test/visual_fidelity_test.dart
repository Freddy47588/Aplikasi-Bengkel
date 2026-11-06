import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show fixtureDatabase, viewport;

void main() {
  testWidgets('operational filters expand and reflow at 320dp with 200% text', (
    tester,
  ) async {
    viewport(tester, 320);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    final container = testContainer(database: await fixtureDatabase());
    addTearDown(container.dispose);
    testAuth(container).signIn(UserRole.admin);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    for (final page in {
      'inventory': 'Filter inventori',
      'technicians': 'Filter teknisi',
    }.entries) {
      router.go('/admin/${page.key}');
      await tester.pumpAndSettle();
      final filter = page.key == 'inventory'
          ? find.byTooltip(page.value)
          : find.text(page.value);
      await reveal(tester, filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      for (var n = 0; n < 8; n++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.key} expanded filter',
        );
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'auth keyboard controls and reset feedback work; vehicle dialog closes with Escape',
    (tester) async {
      viewport(tester, 390);
      final container = testContainer(database: await fixtureDatabase());
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<EditableText>(find.byType(EditableText))
            .last
            .obscureText,
        isFalse,
      );
      await reveal(tester, find.text('Lupa kata sandi'));
      await tester.tap(find.text('Lupa kata sandi'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Isi email yang valid untuk reset kata sandi.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'customer@example.test',
      );
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();
      expect(
        (container.read(authRepositoryProvider) as FakeAuthRepository)
            .calls
            .last,
        'reset:customer@example.test',
      );
      expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
      await reveal(tester, find.text('Kembali ke Login'));
      await tester.tap(find.text('Kembali ke Login'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNWidgets(2));
      testAuth(container).signIn(UserRole.customer);
      router.go('/customer/vehicles');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah kendaraan'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('role dashboard shortcuts still open each existing destination', (
    tester,
  ) async {
    viewport(tester, 390);
    final container = testContainer(database: await fixtureDatabase());
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    for (final role in UserRole.values) {
      testAuth(container).signIn(role);
      final links = <String, String>{
        if (role == UserRole.customer) ...{
          'Booking Servis': 'booking',
          'Kendaraan Saya': 'vehicles',
          'Booking Saya': 'bookings',
        },
        if (role == UserRole.admin) ...{
          'Kelola Booking': 'bookings',
          'Inventory Sparepart': 'inventory',
          'Manajemen Teknisi': 'technicians',
        },
        if (role == UserRole.technician) 'Pekerjaan Saya': 'jobs',
        'Progres Servis': 'orders',
        'Riwayat Servis': 'history',
        if (role != UserRole.technician) 'Invoice & Pembayaran': 'invoices',
      };
      for (final link in links.entries) {
        router.go('/${role.name}/home');
        await tester.pumpAndSettle();
        await reveal(tester, find.text(link.key));
        await tester.tap(find.text(link.key));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/${role.name}/${link.value}',
        );
        expect(tester.takeException(), isNull);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'all target widths and text sizes keep role dashboards and forms scrollable',
    (tester) async {
      viewport(tester, 320);
      final container = testContainer(database: await fixtureDatabase());
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      for (final width in [320.0, 360.0, 390.0, 430.0, 800.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final role in UserRole.values) {
            testAuth(container).signIn(role);
            for (final path in [
              'home',
              if (role == UserRole.customer) 'booking',
              if (role == UserRole.admin) 'inventory',
            ]) {
              router.go('/${role.name}/$path');
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$width/$scale/${role.name}/$path',
              );
              for (var n = 0; n < 6; n++) {
                await tester.drag(
                  find.byType(Scrollable).first,
                  const Offset(0, -600),
                );
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$width/$scale/${role.name}/$path scroll',
                );
              }
              if (path == 'booking') {
                expect(find.byType(WorkshopWave), findsNothing);
              }
              if (path == 'inventory') {
                expect(find.byType(WorkshopWave), findsOneWidget);
                expect(tester.getSize(find.byType(WorkshopWave)).height, 32);
              }
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
