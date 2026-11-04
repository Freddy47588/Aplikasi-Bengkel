import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/data/service_history_repository.dart';
import 'package:bengkel_kendaraan/core/models/service_history.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'history filters reset pagination, detail uses snapshots at 320dp and scale 1.3',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = FakeFirebaseFirestore();
      await db.doc('vehicles/v2').set({
        'ownerId': 'customer-demo',
        'name': 'Brio arsip',
        'plate': 'B 2 AA',
        'active': false,
      });
      await db.doc('services/oil').set({'name': 'Oli', 'active': false});
      await db.doc('serviceOrders/brake').set({
        'status': 'completed',
        'customerId': 'customer-demo',
        'vehicleId': 'v3',
        'vehicleName': 'Avanza',
        'vehiclePlate': 'B 3 CC',
        'serviceId': 'brake',
        'serviceName': 'Rem',
        'completedAt': Timestamp.fromMillisecondsSinceEpoch(1792026000100),
      });
      for (var i = 0; i < 23; i++) {
        await db.doc('serviceOrders/h$i').set({
          'status': 'completed',
          'customerId': 'customer-demo',
          'vehicleId': i == 0 ? 'v2' : 'v',
          'vehicleName': 'Brio',
          'vehiclePlate': 'B 1 AA',
          'serviceId': 'oil',
          'serviceName': 'Oli',
          'bookingId': 'h$i',
          'technicianName': 'Ari',
          'diagnosis': 'Oli kotor',
          'complaint': 'Mesin bising',
          'actions': 'Ganti oli',
          'laborPrice': 75000,
          'completedAt': Timestamp.fromMillisecondsSinceEpoch(
            1792026000000 + i,
          ),
        });
      }
      await db.doc('serviceOrders/h0/partUsages/used').set({
        'kind': 'usage',
        'name': 'Oli',
        'sku': 'OIL',
        'quantity': 1,
        'unit': 'botol',
        'sellPrice': 55000,
        'createdAt': Timestamp.now(),
      });
      await db.doc('serviceOrders/pending').set({
        'status': 'awaitingApproval',
        'customerId': 'customer-demo',
      });
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          firestoreProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.customer);
      final router = container.read(appRouterProvider)..go('/customer/history');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Avanza • B 3 CC'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Avanza • B 3 CC'), findsOneWidget);
      final servicePicker = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Jenis servis',
      );
      await tester.scrollUntilVisible(
        servicePicker,
        -220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(servicePicker);
      await tester.pumpAndSettle();
      // An inactive catalog service remains filterable through its snapshot.
      await tester.tap(find.text('Oli').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Brio • B 1 AA').first,
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Avanza • B 3 CC'), findsNothing);
      Future<void> tapVisible(String label) async {
        await tester.scrollUntilVisible(
          find.text(label),
          220,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tapVisible('Berikutnya');
      expect(find.text('Halaman 2'), findsOneWidget);
      final vehiclePicker = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Kendaraan',
      );
      await tester.scrollUntilVisible(
        vehiclePicker,
        -220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(vehiclePicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brio arsip • B 2 AA').last);
      await tester.pumpAndSettle();
      await tapVisible('Terapkan filter');
      expect(find.text('Halaman 1'), findsOneWidget);
      await tapVisible('Brio • B 1 AA');
      await tapVisible('Referensi dokumen');
      expect(find.text('SO ID: h0'), findsOneWidget);
      await reveal(tester, find.text('Teknisi: Ari'));
      expect(find.text('Teknisi: Ari'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Total biaya: Rp 130.000'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Total biaya: Rp 130.000'), findsOneWidget);
      expect(tester.takeException(), isNull);
      router.go('/customer/history/pending');
      await tester.pumpAndSettle();
      expect(
        find.text('Riwayat servis selesai tidak tersedia.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'history shows loading, empty, error with retry, and offline cache state',
    (tester) async {
      for (final mode in ['loading', 'empty', 'error', 'offline']) {
        var calls = 0;
        final container = ProviderContainer(
          overrides: [
            authSessionProvider.overrideWith(TestAuthController.new),
            firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
            historyPageProvider(const HistoryFilter()).overrideWith((ref) {
              calls++;
              return mode == 'loading'
                  ? const Stream.empty()
                  : mode == 'error'
                  ? Stream.error(StateError('offline'))
                  : Stream.value(
                      RecordPage<ServiceOrder>(
                        const [],
                        null,
                        false,
                        fromCache: mode == 'offline',
                      ),
                    );
            }),
          ],
        );
        testAuth(container).signIn(UserRole.customer);
        container.read(appRouterProvider).go('/customer/history');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BengkelKuApp(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        if (mode == 'loading') {
          expect(find.byType(LinearProgressIndicator), findsOneWidget);
        }
        if (mode == 'empty') {
          expect(
            find.text('Belum ada servis selesai untuk filter ini.'),
            findsOneWidget,
          );
        }
        if (mode == 'offline') {
          expect(find.textContaining('Offline/cache:'), findsOneWidget);
        }
        if (mode == 'error') {
          await tester.ensureVisible(find.text('Coba lagi'));
          await tester.pump();
          await tester.tap(find.text('Coba lagi'));
          await tester.pump();
          expect(calls, greaterThan(1));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
  );
}
