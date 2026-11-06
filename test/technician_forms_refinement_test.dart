import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_completion_screen.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/order_parts_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'technician_refinement_test.dart' show technicianFixture, openTechnician;
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture;

final captureBoundary = GlobalKey();

Future<FakeFirebaseFirestore> formsFixture() async {
  final db = await technicianFixture();
  await db.doc('serviceOrders/task-active').update({
    'checklist': {
      'vehicleChecked': true,
      'safetyChecked': true,
      'workChecked': false,
    },
    'diagnosis': 'Komponen penyaring perlu diganti.',
    'actions': 'Penggantian penyaring dan pemeriksaan mesin.',
    'notes': 'Periksa kembali hasil pekerjaan.',
  });
  final admin = FirestoreInventoryRepository(db, 'admin-demo', UserRole.admin);
  await admin.save(
    const SparepartDraft(
      sku: 'TEST-FILTER',
      name: 'Filter udara uji',
      category: 'Penyaring',
      unit: 'pcs',
      buyPrice: 25000,
      sellPrice: 40000,
      minimumStock: 3,
    ),
  );
  await admin.post(
    const MovementCommand(
      id: 'test-receipt',
      sku: 'TEST-FILTER',
      kind: MovementKind.receipt,
      quantity: 12,
      reason: 'Penerimaan data uji',
    ),
  );
  await admin.post(
    const MovementCommand(
      id: 'test-usage',
      sku: 'TEST-FILTER',
      kind: MovementKind.usage,
      quantity: 2,
      reason: 'Pemakaian data uji',
      serviceOrderId: 'task-active',
    ),
  );
  await db.doc('serviceOrders/task-active/partUsages/test-usage').update({
    'createdAt': Timestamp.fromDate(DateTime.utc(2026, 11, 6, 4)),
  });
  return db;
}

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

  testWidgets(
    'quantity controls enforce bounds and mandatory approval reason',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await formsFixture();
      await openTechnician(tester, db, '/technician/orders/task-active');
      Navigator.push(
        tester.element(find.byType(ServiceOrderDetailScreen)),
        MaterialPageRoute(
          builder: (_) => const PartRequestScreen(orderId: 'task-active'),
        ),
      );
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Tambah jumlah'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field('Qty')).controller!.text, '2');
      await tester.enterText(field('Qty'), '$maxQuantity');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );
      await tester.enterText(field('SKU'), 'TEST-FILTER');
      await tester.enterText(field('Qty'), '0');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Sparepart'));
      await tester.pumpAndSettle();
      expect(find.text('Qty harus 1\u2013$maxQuantity.'), findsOneWidget);
      expect(
        (await db.collection('serviceOrders/task-active/partRequests').get())
            .docs,
        isEmpty,
      );
      await tester.enterText(field('Qty'), '3');
      await tester.tap(find.text('Ajukan Sparepart'));
      await tester.pumpAndSettle();
      expect(
        (await db.collection('serviceOrders/task-active/partRequests').get())
            .docs,
        isEmpty,
      );
      await tester.enterText(
        field('Alasan permintaan'),
        'Penggantian setelah pemeriksaan',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Sparepart'));
      await tester.pumpAndSettle();
      final requests = await db
          .collection('serviceOrders/task-active/partRequests')
          .get();
      expect(requests.docs, hasLength(1));
      expect(requests.docs.single.data()['status'], 'pending');
      expect(requests.docs.single.data()['quantity'], 3);
      expect(
        (await db.doc('spareparts/TEST-FILTER').get()).data()!['stock'],
        10,
      );
    },
  );

  testWidgets(
    'completion rejects stale revision and only submits for approval',
    (tester) async {
      final db = await formsFixture();
      await db.doc('serviceOrders/task-active').update({
        'checklist': {for (final key in inspectionKeys) key: true},
      });
      await openTechnician(tester, db, '/technician/orders/task-active');
      Navigator.push(
        tester.element(find.byType(ServiceOrderDetailScreen)),
        MaterialPageRoute(
          builder: (_) => const ServiceCompletionScreen(orderId: 'task-active'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Selesai'));
      await tester.pumpAndSettle();
      final admin = FirestoreServiceOrderRepository(
        db,
        'admin-demo',
        UserRole.admin,
      );
      await admin.setLaborPrice('task-active', 1, 90000);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('serviceOrders/task-active').get()).data()!['status'],
        'inProgress',
      );
      expect(find.textContaining('Gagal mengajukan:'), findsWidgets);
      await tester.tap(find.text('Ajukan Selesai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('serviceOrders/task-active').get()).data()!['status'],
        'awaitingApproval',
      );
      expect(
        (await db.doc('spareparts/TEST-FILTER').get()).data()!['stock'],
        10,
      );
    },
  );

  testWidgets('forms reflow at supported widths and enlarged text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = await formsFixture();
    final container = await openTechnician(
      tester,
      db,
      '/technician/orders/task-active',
    );
    final order = ServiceOrder(
      'task-active',
      (await db.doc('serviceOrders/task-active').get()).data()!,
    );
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      for (final scale in [1.0, 1.3, 2.0]) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: WorkEditor(order: order),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Diagnosis, tindakan dan catatan'));
        await tester.tap(find.text('Diagnosis, tindakan dan catatan'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Simpan Checklist'));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Checklist $width/$scale',
        );
        for (final page in <Widget>[
          const PartRequestScreen(orderId: 'task-active'),
          const ServiceCompletionScreen(orderId: 'task-active'),
        ]) {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -1800),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType} $width/$scale',
          );
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'technician forms refinement captures checklist request and completion entry',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await formsFixture();
      final container = await openTechnician(
        tester,
        db,
        '/technician/orders/task-active',
      );
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: captureBoundary,
            child: const BengkelKuApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ServiceOrderDetailScreen));
      final order = ServiceOrder(
        'task-active',
        (await db.doc('serviceOrders/task-active').get()).data()!,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => WorkEditor(order: order)),
      );
      await tester.pumpAndSettle();
      await captureCurrent(tester, 'checklist');
      Navigator.pop(tester.element(find.byType(WorkEditor)));
      await tester.pumpAndSettle();
      Navigator.push(
        tester.element(find.byType(ServiceOrderDetailScreen)),
        MaterialPageRoute(
          builder: (_) => const PartRequestScreen(orderId: 'task-active'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'TEST-FILTER');
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Penggantian sesuai pemeriksaan',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await captureCurrent(tester, 'part-request');
      Navigator.pop(tester.element(find.byType(PartRequestScreen)));
      await db.doc('serviceOrders/task-active').update({
        'checklist': {for (final key in inspectionKeys) key: true},
      });
      router.go('/technician/orders/task-active');
      await tester.pumpAndSettle();
      Navigator.push(
        tester.element(find.byType(ServiceOrderDetailScreen)),
        MaterialPageRoute(
          builder: (_) => const ServiceCompletionScreen(orderId: 'task-active'),
        ),
      );
      await tester.pumpAndSettle();
      await captureCurrent(tester, 'completion');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

Future<void> captureCurrent(WidgetTester tester, String name) async {
  await captureFixture(tester, captureBoundary, 'refinement-$name');
}
