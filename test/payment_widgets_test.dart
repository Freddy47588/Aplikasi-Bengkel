import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/data/payment_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void main() {
  for (final role in [UserRole.admin, UserRole.customer]) {
    testWidgets(
      'invoice detail ${role.name} fits 320dp scale 1.3 and enforces action visibility',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final db = FakeFirebaseFirestore();
        await db.doc('serviceOrders/so').set({
          'status': 'completed',
          'customerId': 'customer-demo',
          'serviceName': 'Ganti oli',
          'vehiclePlate': 'B 1 AA',
          'laborPrice': 75000,
        });
        await PaymentRepository(
          db,
          'admin-demo',
          UserRole.admin,
        ).create('so', reason: 'Final');
        final container = ProviderContainer(
          overrides: [
            authSessionProvider.overrideWith(TestAuthController.new),
            firestoreProvider.overrideWithValue(db),
          ],
        );
        addTearDown(container.dispose);
        testAuth(container).signIn(role);
        container.read(appRouterProvider).go('/${role.name}/invoices/so');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const BengkelKuApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('INV~so'), findsOneWidget);
        Future<void> visible(String label) async {
          await tester.scrollUntilVisible(
            find.text(label),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
        }

        if (role == UserRole.admin) {
          await visible('Catat pembayaran');
          await tester.tap(find.text('Catat pembayaran'));
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.text('Konfirmasi tindakan'), findsOneWidget);
          await tester.tap(find.text('Kembali'));
          await tester.pumpAndSettle();
          expect((await db.doc('invoices/so').get()).data()!['paidAmount'], 0);
        } else {
          await visible('Audit pembayaran');
          expect(find.text('Catat pembayaran'), findsNothing);
          expect(find.text('Void invoice'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
