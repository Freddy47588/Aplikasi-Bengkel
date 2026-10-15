import 'dart:async';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/inventory_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'test_support.dart';
import 'inventory_repository_test.dart' show draft, command;

class MockInventory extends Mock implements InventoryRepository {}

void main() {
  setUpAll(() => registerFallbackValue(command('fallback')));
  testWidgets(
    'double tap and retry after lost acknowledgement reuse same ID and decrement exactly once',
    (tester) async {
      final db = FakeFirebaseFirestore(), mock = MockInventory();
      final real = FirestoreInventoryRepository(db, 'admin', UserRole.admin);
      await real.save(draft());
      await real.post(command('receipt'));
      await db.doc('serviceOrders/so').set({'status': 'inProgress'});
      final pending = Completer<void>();
      final commands = <MovementCommand>[];
      when(() => mock.newOperationId()).thenReturn('stable');
      when(() => mock.post(any())).thenAnswer((call) async {
        final c = call.positionalArguments.first as MovementCommand;
        commands.add(c);
        if (commands.length == 1) await pending.future;
        final result = await real.post(c);
        if (commands.length == 1) {
          throw StateError('Acknowledgement lost after commit');
        }
        return result;
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [inventoryRepositoryProvider.overrideWithValue(mock)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const StockOperationScreen(sku: 'OIL', orderId: 'so'),
                    ),
                  ),
                  child: const Text('Buka transaksi'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka transaksi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.enterText(find.byType(TextFormField).at(2), 'Ganti oli');
      await tester.tap(find.text('Catat transaksi'));
      await tester.tap(find.text('Catat transaksi'));
      await tester.pump();
      expect(commands.length, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect((await real.get('OIL'))!.stock, 3);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).at(1)).enabled,
        false,
      );
      await tester.tap(find.text('Coba lagi operasi yang sama'));
      await tester.pumpAndSettle();
      expect(commands.map((c) => c.id).toList(), ['stable', 'stable']);
      expect((await real.get('OIL'))!.stock, 3);
      expect((await db.collection('stockMovements').get()).docs.length, 2);
      expect(find.text('Buka transaksi'), findsOneWidget);
    },
  );

  testWidgets(
    'inventory filter low stock and SKU search use repository; master form scrolls at 320dp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      final repo = FirestoreInventoryRepository(db, 'admin', UserRole.admin);
      await repo.save(draft());
      await repo.post(command('receipt'));
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          firestoreProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.admin);
      final router = container.read(appRouterProvider);
      router.go('/admin/inventory');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('OIL • Oli mesin'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada sparepart sesuai filter.'), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'other');
      await tester.tap(find.text('Terapkan pencarian'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada sparepart sesuai filter.'), findsOneWidget);
      await tester.tap(find.byTooltip('Tambah sparepart'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Simpan master'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(SparepartEditor),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Simpan master'));
      await tester.pumpAndSettle();
      expect(find.byType(SparepartEditor), findsOneWidget);
      expect((await db.collection('spareparts').get()).docs.length, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
