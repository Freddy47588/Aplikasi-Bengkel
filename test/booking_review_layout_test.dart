import 'test_support.dart';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('500 character booking review fits 320dp at text scale 1.3', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = testContainer();
    addTearDown(container.dispose);
    testAuth(container).signIn(UserRole.customer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    container.read(appRouterProvider).go('/customer/booking');
    await tester.pumpAndSettle();
    Future<void> tapVisible(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tapVisible(find.byType(DropdownButtonFormField<String>).first);
    await tapVisible(find.text('Honda Brio RS • B 1234 XYZ').last);
    await tapVisible(find.byType(DropdownButtonFormField<String>).last);
    await tapVisible(find.text('Ganti Oli').last);
    await tapVisible(find.text('Pilih tanggal servis'));
    await tapVisible(find.text('OK'));
    await tapVisible(find.byType(DropdownButtonFormField<int>));
    await tapVisible(find.text('09:00').last);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      ('Keluhan kendaraan. ' * 30).substring(0, 500),
    );
    await tapVisible(find.text('Konfirmasi Booking'));
    expect(tester.takeException(), isNull);
    await tapVisible(find.text('Kirim Booking'));
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      startsWith('/customer/bookings/BKG-'),
    );
    await tester.scrollUntilVisible(
      find.text('Menunggu'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Menunggu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
