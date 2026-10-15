import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'assigned task starts and customer sees realtime progress; work form fits small screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      final admin = FirestoreServiceOrderRepository(
        db,
        'admin',
        UserRole.admin,
      );
      await db.doc('users/technician-demo').set({
        'role': 'technician',
        'active': true,
      });
      await admin.saveTechnician('technician-demo', 'Ari', 'Mesin', true, true);
      await db.doc('bookings/one').set({
        'customerId': 'customer-demo',
        'vehicleId': 'v',
        'vehicleName': 'Brio',
        'vehiclePlate': 'B 1234 AA',
        'serviceId': 'oil',
        'serviceName': 'Oli',
        'complaint': 'Mesin bising',
        'scheduledAt': Timestamp.now(),
        'status': 'confirmed',
      });
      await admin.create('one');
      await admin.assign('one', 'technician-demo', 0);
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          firestoreProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.technician);
      final router = container.read(appRouterProvider);
      router.go('/technician/orders/one');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Keluhan: Mesin bising'), findsOneWidget);
      await tester.ensureVisible(find.text('Dikerjakan'));
      await tester.tap(find.text('Dikerjakan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(find.text('Status: Dikerjakan'), findsOneWidget);
      await tester.ensureVisible(find.text('Checklist dan catatan kerja'));
      await tester.tap(find.text('Checklist dan catatan kerja'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.enterText(find.byType(TextField).first, 'Pemeriksaan mesin');
      await tester.scrollUntilVisible(
        find.text('Simpan'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('serviceOrders/one').get())['diagnosis'],
        'Pemeriksaan mesin',
      );
      testAuth(container).signIn(UserRole.customer);
      router.go('/customer/orders/one');
      await tester.pumpAndSettle();
      expect(find.text('Diagnosis: Pemeriksaan mesin'), findsOneWidget);
      expect(find.text('Checklist dan catatan kerja'), findsNothing);
      final tech = FirestoreServiceOrderRepository(
        db,
        'technician-demo',
        UserRole.technician,
      );
      await tech.updateWork(
        'one',
        3,
        status: ServiceOrderStatus.paused,
        checklist: {for (final k in inspectionKeys) k: false},
        diagnosis: 'Pemeriksaan mesin',
        actions: '',
        notes: 'Jeda',
      );
      await tester.pumpAndSettle();
      expect(find.text('Status: Dijeda'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('order list exposes loading empty error and retry', (
    tester,
  ) async {
    for (final mode in ['loading', 'empty', 'error']) {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          ordersPageProvider(null).overrideWith(
            (ref) => mode == 'loading'
                ? const Stream.empty()
                : mode == 'error'
                ? Stream.error(StateError('offline'))
                : Stream.value(const RecordPage([], null, false)),
          ),
        ],
      );
      testAuth(container).signIn(UserRole.technician);
      final router = container.read(appRouterProvider);
      router.go('/technician/jobs');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      if (mode == 'loading') {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
      if (mode == 'empty') {
        expect(
          find.text('Belum ada Service Order di halaman ini.'),
          findsOneWidget,
        );
      }
      if (mode == 'error') {
        expect(find.text('Gagal memuat. Coba lagi'), findsOneWidget);
        await tester.tap(find.text('Gagal memuat. Coba lagi'));
        await tester.pump();
      }
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
  });
}
