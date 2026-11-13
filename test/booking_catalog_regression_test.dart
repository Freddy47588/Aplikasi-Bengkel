import 'dart:async';

import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/data/service_repository.dart';
import 'package:bengkel_kendaraan/core/data/vehicle_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'test_support.dart';

void main() {
  late ProviderContainer container;
  late StreamController<List<WorkshopService>> services;
  late StreamController<List<Vehicle>> vehicles;

  Future<void> open(WidgetTester tester) async {
    services = StreamController<List<WorkshopService>>.broadcast(
      onListen: () => scheduleMicrotask(() {
        services.add([const WorkshopService('oil', 'Ganti Oli')]);
      }),
    );
    vehicles = StreamController<List<Vehicle>>.broadcast(
      onListen: () => scheduleMicrotask(() => vehicles.add(demoVehicles)),
    );
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        authSessionProvider.overrideWith(TestAuthController.new),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        bookingRepositoryProvider.overrideWith((ref) {
          final repo = InMemoryBookingRepository();
          ref.onDispose(repo.dispose);
          return repo;
        }),
        servicesProvider.overrideWith((ref) => services.stream),
        vehiclesProvider.overrideWith((ref) => vehicles.stream),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await services.close();
      await vehicles.close();
    });
    testAuth(container).signIn(UserRole.customer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    container.read(appRouterProvider).go('/customer/booking');
    await tester.pump();
    services.add([const WorkshopService('oil', 'Ganti Oli')]);
    vehicles.add(demoVehicles);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tap(tester, find.byType(DropdownButtonFormField<String>).first);
    await tap(tester, find.text('Honda Brio RS • B 1234 XYZ').last);
    await tap(tester, find.byType(DropdownButtonFormField<String>).last);
    await tap(tester, find.text('Ganti Oli').last);
    await tap(tester, find.text('Pilih tanggal servis'));
    await tap(tester, find.text('OK'));
    await tap(tester, find.byType(DropdownButtonFormField<int>));
    await tap(tester, find.text('09:00').last);
    await reveal(tester, find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Rem berbunyi keras');
    await reveal(tester, find.text('Konfirmasi Booking'));
  }

  testWidgets('rapid confirmation opens one review and cancel unlocks form', (
    tester,
  ) async {
    await open(tester);
    await fill(tester);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Konfirmasi Booking'),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konfirmasi Booking'),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      (container.read(bookingRepositoryProvider) as InMemoryBookingRepository)
          .snapshot,
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('review keeps its snapshot when selected vehicle is archived', (
    tester,
  ) async {
    await open(tester);
    await fill(tester);
    await tap(tester, find.text('Konfirmasi Booking'));
    vehicles.add([]);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(700, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Honda Brio RS').last, findsOneWidget);
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('catalog error disables submit and retry restores real options', (
    tester,
  ) async {
    await open(tester);
    services.addError(StateError('catalog offline'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Konfirmasi Booking'));
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konfirmasi Booking'),
          )
          .onPressed,
      isNull,
    );
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await tap(tester, find.text('Gagal memuat katalog. Coba lagi'));
    await tap(tester, find.byType(DropdownButtonFormField<String>).last);
    await tap(tester, find.text('Ganti Oli').last);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('service removal clears selection and returning catalog opens', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.byType(DropdownButtonFormField<String>).last);
    await tap(tester, find.text('Ganti Oli').last);
    services.add([]);
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada layanan aktif. Hubungi pengelola bengkel.'),
      findsOneWidget,
    );
    services.add([const WorkshopService('brake', 'Servis Rem')]);
    await tester.pumpAndSettle();
    await tap(tester, find.byType(DropdownButtonFormField<String>).last);
    await tap(tester, find.text('Servis Rem').last);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'catalog changes before next frame cannot escape submit handler',
    (tester) async {
      await open(tester);
      await fill(tester);
      final submit = tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Konfirmasi Booking'),
          )
          .onPressed!;
      await tester.runAsync(() async {
        services.add([]);
        await Future<void>.delayed(Duration.zero);
      });
      submit();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        (container.read(bookingRepositoryProvider) as InMemoryBookingRepository)
            .snapshot,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
