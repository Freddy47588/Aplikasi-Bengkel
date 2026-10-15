import 'test_support.dart';
import 'dart:async';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'router stays alive across role changes; guards and nav track active route',
    (tester) async {
      final container = testContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      final router = container.read(appRouterProvider);
      for (final role in UserRole.values) {
        testAuth(container).signIn(role);
        await tester.pumpAndSettle();
        expect(identical(router, container.read(appRouterProvider)), isTrue);
        expect(
          router.routeInformationProvider.value.uri.path,
          '/${role.name}/home',
        );
        router.go(
          role == UserRole.admin
              ? '/admin/technicians'
              : '/${role.name}/${role == UserRole.customer ? 'booking' : 'jobs'}',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          role == UserRole.admin ? 2 : 1,
        );
        router.go(
          role == UserRole.customer ? '/admin/bookings' : '/customer/booking',
        );
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/${role.name}/home',
        );
        testAuth(container).signOut();
        await tester.pumpAndSettle();
        expect(find.text('Masuk'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'customer creates booking, admin confirms, customer sees status and cancels',
    (tester) async {
      final container = testContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      final router = container.read(appRouterProvider);
      final auth = testAuth(container);
      auth.signIn(UserRole.customer);
      router.go('/customer/booking');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Konfirmasi Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih kendaraan.'), findsOneWidget);
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Honda Brio RS • B 1234 XYZ').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ganti Oli').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pilih tanggal servis'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('09:00').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Mesin berbunyi keras',
      );
      await tester.ensureVisible(find.text('Konfirmasi Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Menunggu'), findsOneWidget);
      final id = container.read(bookingsProvider).asData!.value.single.id;
      auth.signOut();
      await tester.pumpAndSettle();
      auth.signIn(UserRole.admin);
      router.go('/admin/bookings/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Dikonfirmasi'), findsOneWidget);
      auth.signOut();
      await tester.pumpAndSettle();
      auth.signIn(UserRole.customer);
      router.go('/customer/bookings/$id');
      await tester.pumpAndSettle();
      expect(find.text('Dikonfirmasi'), findsOneWidget);
      await tester.tap(find.text('Batalkan Booking'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Dibatalkan'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('booking loading, empty, error and retry states', (tester) async {
    final stream = StreamController<List<Booking>>.broadcast();
    final container = testContainer(bookings: stream.stream);
    addTearDown(() async {
      container.dispose();
      await stream.close();
    });
    testAuth(container).signIn(UserRole.admin);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    container.read(appRouterProvider).go('/admin/bookings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    stream.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada booking'), findsOneWidget);
    stream.addError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Gagal memuat booking.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    stream.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada booking'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'small screen keyboard allows complaint and submission to scroll into view',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
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
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Rem berbunyi');
      await tester.ensureVisible(find.text('Konfirmasi Booking'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Booking').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(430, 932),
    const Size(1280, 800),
  ]) {
    testWidgets('main pages fit $size at enlarged text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = testContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: const BengkelKuApp(),
          ),
        ),
      );
      final router = container.read(appRouterProvider);
      expect(tester.takeException(), isNull, reason: 'login $size');
      for (final role in UserRole.values) {
        testAuth(container).signIn(role);
        for (final path in [
          'home',
          role == UserRole.customer
              ? 'booking'
              : role == UserRole.admin
              ? 'bookings'
              : 'jobs',
          'history',
          'profile',
        ]) {
          router.go('/${role.name}/$path');
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${role.name}/$path $size',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('system back from booking detail returns to the booking list', (
    tester,
  ) async {
    final container = testContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    final router = container.read(appRouterProvider);
    for (final role in [UserRole.customer, UserRole.admin]) {
      testAuth(container).signIn(role);
      router.go('/${role.name}/bookings/missing');
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        role == UserRole.customer ? 2 : 1,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/${role.name}/bookings',
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('admin rejects and customer cannot cancel rejected booking', (
    tester,
  ) async {
    final container = testContainer();
    addTearDown(container.dispose);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final booking = await container
        .read(bookingRepositoryProvider)
        .submit(
          'customer-demo',
          BookingDraft(
            vehicleId: 'brio',
            service: 'Ganti Oli',
            scheduledAt: DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day,
              9,
            ),
            complaint: 'Rem berbunyi saat digunakan',
          ),
        );
    testAuth(container).signIn(UserRole.admin);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    final router = container.read(appRouterProvider);
    router.go('/admin/bookings/${booking.id}');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tolak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.text('Ditolak'), findsOneWidget);
    testAuth(container).signOut();
    await tester.pumpAndSettle();
    testAuth(container).signIn(UserRole.customer);
    router.go('/customer/bookings/${booking.id}');
    await tester.pumpAndSettle();
    expect(find.text('Ditolak'), findsOneWidget);
    expect(find.text('Batalkan Booking'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
