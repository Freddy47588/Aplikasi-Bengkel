import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/order_parts_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/admin_service_ui.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technicians_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'technician_forms_refinement_test.dart' show formsFixture;
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture;

Future<FakeFirebaseFirestore> adminFixture() async {
  final db = await formsFixture();
  for (final (id, name, active) in [
    ('technician-demo', 'Raka', true),
    ('available-tech', 'Sinta', true),
    ('inactive-tech', 'Tegar', false),
  ]) {
    await db.doc('users/$id').set({'role': 'technician', 'active': active});
    await db.doc('technicians/$id').set({
      'name': name,
      'specialization': 'Mesin',
      'active': active,
      'available': true,
      'currentOrderId': id == 'technician-demo' ? 'task-active' : null,
    });
  }
  return db;
}

Future<ProviderContainer> openAdmin(
  WidgetTester tester,
  FakeFirebaseFirestore db,
  String path, {
  GlobalKey? boundary,
}) async {
  final container = testContainer(database: db);
  addTearDown(container.dispose);
  testAuth(container).signIn(UserRole.admin);
  container.read(appRouterProvider).go(path);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: boundary, child: const BengkelKuApp()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
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
    'admin searches technicians edits activity and opens create form',
    (tester) async {
      final db = await adminFixture();
      await openAdmin(tester, db, '/admin/technicians');
      await tester.enterText(find.byType(TextField).first, 'Sin');
      await tester.pumpAndSettle();
      expect(find.text('Sinta'), findsOneWidget);
      expect(find.text('Raka'), findsNothing);
      await tester.tap(find.text('Sinta'));
      await tester.pumpAndSettle();
      expect(find.byType(TechnicianEditor), findsOneWidget);
      await reveal(tester, find.text('Aktif'));
      await tester.tap(find.text('Aktif'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('technicians/available-tech').get()).data()!['active'],
        false,
      );
      await tester.tap(find.text('Tambah Teknisi'));
      await tester.pumpAndSettle();
      expect(find.byType(TechnicianEditor), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'UID akun teknisi'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'admin assignment pricing approval and terminal actions stay valid',
    (tester) async {
      final db = await adminFixture();
      await db.doc('serviceOrders/task-active').update({
        'status': 'queued',
        'technicianId': null,
        'technicianName': '',
        'laborPrice': null,
      });
      await db.doc('technicians/technician-demo').update({
        'currentOrderId': null,
      });
      final container = await openAdmin(
        tester,
        db,
        '/admin/orders/task-active',
      );
      Future<void> tap(String label) async {
        await reveal(tester, find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tap('Assign / alihkan teknisi');
      await tap('Sinta');
      expect(
        (await db.doc('serviceOrders/task-active').get())
            .data()!['technicianId'],
        'available-tech',
      );
      expect(
        (await db.doc('technicians/available-tech').get())
            .data()!['currentOrderId'],
        'task-active',
      );
      await db.doc('serviceOrders/task-active').update({
        'status': 'awaitingApproval',
        'checklist': {for (final key in inspectionKeys) key: true},
      });
      await tester.pumpAndSettle();
      await tap('Setujui penyelesaian');
      await tap('Lanjutkan');
      expect(
        (await db.doc('serviceOrders/task-active').get()).data()!['status'],
        'awaitingApproval',
      );
      expect(find.textContaining('Catat biaya jasa'), findsWidgets);
      await tap('Catat biaya jasa');
      await tester.enterText(find.byType(TextField), '-1');
      await tap('Simpan');
      expect(find.text('Masukkan 0 sampai 1000000000 rupiah.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '0');
      await tap('Simpan');
      await tap('Setujui penyelesaian');
      await tap('Lanjutkan');
      final data = (await db.doc('serviceOrders/task-active').get()).data()!;
      expect(data['status'], 'completed');
      expect(data['laborPrice'], 0);
      expect(
        (await db.doc('technicians/available-tech').get())
            .data()!['currentOrderId'],
        isNull,
      );
      expect(find.text('Catat biaya jasa'), findsNothing);
      expect(find.text('Assign / alihkan teknisi'), findsNothing);
      expect(find.text('Batalkan pekerjaan'), findsNothing);
      final repo = container.read(serviceOrderRepositoryProvider);
      await expectLater(
        repo.setLaborPrice('task-active', data['revision'] as int, 1),
        throwsStateError,
      );
      expect(
        (await db.collection('serviceOrders/task-active/events').get()).docs,
        isNotEmpty,
      );
      testAuth(container).signIn(UserRole.customer);
      container.read(appRouterProvider).go('/admin/technicians');
      await tester.pumpAndSettle();
      expect(find.byType(TechniciansScreen), findsNothing);
    },
  );

  testWidgets('admin order search and filter retain actual status and scope', (
    tester,
  ) async {
    await openAdmin(tester, await adminFixture(), '/admin/orders');
    await tester.enterText(find.byType(TextField).first, 'N 4218 TEST');
    await tester.pumpAndSettle();
    expect(find.text('task-active'), findsOneWidget);
    expect(find.text('task-done-a'), findsNothing);
    await tester.tap(find.byTooltip('Filter Service Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<ServiceOrderStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai').last);
    await tester.pumpAndSettle();
    expect(find.text('task-active'), findsNothing);
    expect(find.text('Service Order belum ditemukan'), findsOneWidget);
  });

  testWidgets(
    'admin screens reflow at phone widths and all seven status actions',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final db = await adminFixture();
      final container = await openAdmin(tester, db, '/admin/home');
      final router = container.read(appRouterProvider);
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final path in [
            '/admin/technicians',
            '/admin/orders',
            '/admin/orders/task-active',
          ]) {
            router.go(path);
            await tester.pumpAndSettle();
            final filter = find.byTooltip(
              path == '/admin/technicians'
                  ? 'Filter teknisi'
                  : 'Filter Service Order',
            );
            if (!path.endsWith('task-active')) {
              await tester.tap(filter);
              await tester.pumpAndSettle();
            }
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -1600),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$path $width/$scale',
            );
          }
        }
      }
      for (final status in ServiceOrderStatus.values) {
        await db.doc('serviceOrders/task-active').update({
          'status': status.name,
        });
        await tester.pumpAndSettle();
        final view = tester.widget<AdminOrderDetail>(
          find.byType(AdminOrderDetail),
        );
        expect(view.order.status, status);
        expect(
          find.text('Assign / alihkan teknisi').evaluate().isNotEmpty,
          ['queued', 'assigned', 'paused'].contains(status.name),
        );
        expect(
          find.text('Setujui penyelesaian').evaluate().isNotEmpty,
          status == ServiceOrderStatus.awaitingApproval,
        );
        expect(
          find.text('Catat biaya jasa').evaluate().isNotEmpty,
          !status.terminal,
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('admin parts summary refreshes after transaction navigation', (
    tester,
  ) async {
    final db = await adminFixture();
    await openAdmin(tester, db, '/admin/orders/task-active');
    await reveal(tester, find.text('Sparepart dan permintaan'));
    await tester.tap(find.text('Sparepart dan permintaan'));
    await tester.pumpAndSettle();
    final repo = FirestoreInventoryRepository(db, 'admin-demo', UserRole.admin);
    await repo.post(
      const MovementCommand(
        id: 'extra-usage',
        sku: 'TEST-FILTER',
        kind: MovementKind.usage,
        quantity: 3,
        reason: 'Pemakaian tambahan uji',
        serviceOrderId: 'task-active',
      ),
    );
    Navigator.pop(tester.element(find.byType(OrderPartsScreen)));
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Dipakai: 3 pcs'));
    expect(find.text('Dipakai: 3 pcs'), findsOneWidget);
    expect(find.text('Rp 40.000 / pcs'), findsWidgets);
    expect((await db.doc('spareparts/TEST-FILTER').get()).data()!['stock'], 7);
  });

  testWidgets('admin refinement captures technicians orders and detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final container = await openAdmin(
      tester,
      await adminFixture(),
      '/admin/technicians',
      boundary: boundary,
    );
    final router = container.read(appRouterProvider);
    for (final (path, name) in [
      ('/admin/technicians', 'technicians'),
      ('/admin/orders', 'orders'),
      ('/admin/orders/task-active', 'order-detail'),
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      await captureFixture(tester, boundary, 'admin-refinement-$name');
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
