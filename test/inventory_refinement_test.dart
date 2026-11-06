import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/app/theme/app_theme.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/inventory_screen.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/inventory_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture, fixtureDatabase;
import 'inventory_repository_test.dart' show command;

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
  testWidgets('inventory refinement renders three current screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await fixtureDatabase();
    await db.doc('spareparts/OIL').update({'stockRevision': 0});
    final repo = FirestoreInventoryRepository(db, 'admin-demo', UserRole.admin);
    for (final (sku, name, stock, minimum) in [
      ('AIR', 'Filter udara', 16, 4),
      ('BRAKE', 'Kampas rem', 0, 3),
      ('CHAIN', 'Rantai motor', 4, 5),
      ('PLUG', 'Busi', 18, 6),
    ]) {
      await repo.save(
        SparepartDraft(
          sku: sku,
          name: name,
          category: 'Komponen',
          unit: 'pcs',
          buyPrice: 20000,
          sellPrice: 30000,
          minimumStock: minimum,
        ),
      );
      if (stock > 0) {
        await repo.post(
          MovementCommand(
            id: 'fixture-$sku',
            sku: sku,
            kind: MovementKind.receipt,
            quantity: stock,
            reason: 'Penerimaan barang uji',
          ),
        );
      }
    }
    await repo.post(
      const MovementCommand(
        id: 'fixture-oil',
        sku: 'OIL',
        kind: MovementKind.receipt,
        quantity: 6,
        reason: 'Penerimaan pelumas uji',
      ),
    );
    await db.doc('serviceOrders/assigned').update({'status': 'inProgress'});
    await repo.post(
      const MovementCommand(
        id: 'fixture-usage',
        sku: 'OIL',
        kind: MovementKind.usage,
        quantity: 2,
        reason: 'Pemakaian servis uji',
        serviceOrderId: 'assigned',
      ),
    );
    await repo.post(
      const MovementCommand(
        id: 'fixture-adjust',
        sku: 'OIL',
        kind: MovementKind.adjustment,
        quantity: 1,
        reason: 'Hasil pemeriksaan stok uji',
      ),
    );
    final movements = await db.collection('stockMovements').get();
    for (var i = 0; i < movements.docs.length; i++) {
      await movements.docs[i].reference.update({
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 6, 8, i * 5)),
      });
    }
    final container = testContainer(database: db);
    addTearDown(container.dispose);
    testAuth(container).signIn(UserRole.admin);
    final key = GlobalKey();
    for (final (name, screen) in <(String, Widget)>[
      ('inventory', const InventoryScreen()),
      ('stock-detail', const SparepartDetailScreen(sku: 'OIL')),
      ('stock-ledger', const StockLedgerScreen()),
    ]) {
      final router = GoRouter(
        routes: [GoRoute(path: '/', builder: (_, _) => screen)],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'refinement-$name');
      expect(tester.takeException(), isNull, reason: name);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    }
  });

  testWidgets(
    'three stock screens reflow at all phone widths and text scales',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = testContainer(database: await fixtureDatabase());
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.admin);
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final screen in <Widget>[
            const InventoryScreen(),
            const SparepartDetailScreen(sku: 'OIL'),
            const StockLedgerScreen(),
          ]) {
            final router = GoRouter(
              routes: [GoRoute(path: '/', builder: (_, _) => screen)],
            );
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp.router(
                  theme: buildAppTheme(),
                  routerConfig: router,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final filter = screen is InventoryScreen
                ? find.byTooltip('Filter inventori')
                : find.byTooltip('Filter riwayat stok');
            if (screen is! SparepartDetailScreen) {
              await reveal(tester, filter);
              await tester.tap(filter);
              await tester.pumpAndSettle();
            }
            for (var i = 0; i < 5; i++) {
              await tester.drag(
                find.byType(Scrollable).first,
                const Offset(0, -300),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$width / $scale / ${screen.runtimeType}',
              );
            }
            await tester.pumpWidget(const SizedBox());
            router.dispose();
          }
        }
      }
    },
  );

  testWidgets(
    'stock badges follow quantity and minimum including the boundary and archive',
    (tester) async {
      for (final (stock, active, expected) in [
        (0, true, 'Habis'),
        (2, true, 'Minimum'),
        (3, true, 'Aman'),
        (0, false, 'Nonaktif'),
      ]) {
        final part = Sparepart('OIL', {
          'stock': stock,
          'minimumStock': 2,
          'active': active,
          'lowStock': false,
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: StockBadge(part: part)),
          ),
        );
        expect(find.text(expected), findsOneWidget);
      }
    },
  );

  testWidgets(
    'stock actions open supported kinds and outgoing requires a service order',
    (tester) async {
      final db = await fixtureDatabase();
      await db.doc('spareparts/OIL').update({'stockRevision': 0, 'stock': 8});
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.admin);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const SparepartDetailScreen(sku: 'OIL'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Stok Keluar'));
      await tester.tap(find.text('Stok Keluar'));
      await tester.pumpAndSettle();
      expect(find.text('ID Service Order'), findsOneWidget);
      await reveal(tester, find.text('Catat transaksi'));
      await tester.tap(find.text('Catat transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('ID Service Order wajib.'), findsOneWidget);
      expect((await db.collection('stockMovements').get()).docs, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(0), 'assigned');
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Servis terjadwal',
      );
      await tester.tap(find.text('Catat transaksi'));
      await tester.pumpAndSettle();
      expect((await db.doc('spareparts/OIL').get())['stock'], 6);
      await reveal(tester, find.text('Stok Masuk'));
      await tester.tap(find.text('Stok Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('ID Service Order'), findsNothing);
      await tester.enterText(find.byType(TextFormField).at(0), '3');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Penerimaan gudang',
      );
      await tester.tap(find.text('Catat transaksi'));
      await tester.pumpAndSettle();
      expect((await db.doc('spareparts/OIL').get())['stock'], 9);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ledger pagination, exact SKU and SO filters preserve history and reversal',
    (tester) async {
      final db = await fixtureDatabase();
      await db.doc('spareparts/OIL').update({'stockRevision': 0});
      final repo = FirestoreInventoryRepository(
        db,
        'admin-demo',
        UserRole.admin,
      );
      for (var i = 0; i < 23; i++) {
        await repo.post(command('receipt-$i', quantity: 1));
        await db.doc('stockMovements/receipt-$i').update({
          'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 6, 0, i)),
        });
      }
      await repo.post(
        command(
          'usage',
          kind: MovementKind.usage,
          quantity: 2,
          so: 'assigned',
          reason: 'Penggantian uji',
        ),
      );
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.admin);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const StockLedgerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Berikutnya'));
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Halaman 2'), findsOneWidget);
      await reveal(tester, find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada riwayat stok'), findsOneWidget);
      expect(find.text('Halaman 1'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'oil');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filter riwayat stok'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'assigned');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(StockMovementCard), findsOneWidget);
      final details = find.descendant(
        of: find.byType(StockMovementCard),
        matching: find.byType(ExpansionTile),
      );
      await reveal(tester, details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Reversal penuh'));
      await tester.tap(find.text('Reversal penuh'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Pembatalan pemakaian uji',
      );
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect((await db.doc('spareparts/OIL').get())['stock'], 24);
      expect((await db.doc('stockMovements/R~usage').get()).exists, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
