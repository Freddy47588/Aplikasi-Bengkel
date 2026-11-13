import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';
import 'ui_ux_polish_test.dart' show fixtureDatabase, viewport;

void main() {
  testWidgets('all role routes remain scrollable at 150 percent text', (
    tester,
  ) async {
    viewport(tester, 320);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
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
      tester.view.physicalSize = Size(width, 740);
      for (final role in UserRole.values) {
        testAuth(container).signIn(role);
        for (final page in [
          'home',
          'profile',
          'orders',
          'history',
          if (role == UserRole.customer) ...['booking', 'vehicles', 'bookings'],
          if (role == UserRole.admin) ...[
            'bookings',
            'technicians',
            'inventory',
          ],
          if (role == UserRole.technician) 'jobs',
          if (role != UserRole.technician) 'invoices',
        ]) {
          final route = '/${role.name}/$page';
          router.go(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$width/$route');
          expect(router.routeInformationProvider.value.uri.path, route);
          for (var i = 0; i < 5; i++) {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$width/$route scroll',
            );
          }
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}
