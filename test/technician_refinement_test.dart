import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technician_overview.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technician_task_ui.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_completion_screen.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/order_parts_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture;

Future<FakeFirebaseFirestore> technicianFixture() async {
  final db = FakeFirebaseFirestore();
  await db.doc('technicians/technician-demo').set({
    'name': 'Raka',
    'specialization': 'Mesin',
    'active': true,
    'available': true,
    'currentOrderId': 'task-active',
  });
  for (final (id, status, plate, vehicle, day) in [
    ('task-active', 'inProgress', 'N 4218 TEST', 'Honda Brio', 6),
    ('task-done-a', 'completed', 'N 5152 TEST', 'Yamaha Mio', 5),
    ('task-done-b', 'completed', 'N 9271 TEST', 'Toyota Calya', 4),
    ('task-cancelled', 'cancelled', 'N 8316 TEST', 'Suzuki Ertiga', 3),
    ('task-other', 'assigned', 'OTHER PRIVATE', 'Kendaraan teknisi lain', 6),
  ]) {
    final at = Timestamp.fromDate(DateTime.utc(2026, 11, day, 2));
    await db.doc('serviceOrders/$id').set({
      'status': status,
      'revision': 1,
      'customerId': 'customer-demo',
      'technicianId': id == 'task-other'
          ? 'other-technician'
          : 'technician-demo',
      'technicianName': id == 'task-other' ? 'Teknisi lain' : 'Raka',
      'vehicleName': vehicle,
      'vehiclePlate': plate,
      'vehicleId': 'vehicle-$id',
      'serviceId': 'periodic',
      'serviceName': 'Pemeriksaan berkala',
      'complaint': 'Mesin bergetar saat kendaraan berhenti.',
      'checklist': {
        for (final key in inspectionKeys) key: status == 'completed',
      },
      'diagnosis': status == 'completed' ? 'Pemeriksaan selesai' : '',
      'actions': status == 'completed' ? 'Penyetelan mesin' : '',
      'notes': '',
      'laborPrice': 75000,
      'scheduledAt': at,
      'createdAt': at,
      'updatedAt': at,
      'assignedAt': at,
      'startedAt': status == 'inProgress' || status == 'completed' ? at : null,
      'completedAt': status == 'completed' ? at : null,
    });
  }
  return db;
}

Future<ProviderContainer> openTechnician(
  WidgetTester tester,
  FakeFirebaseFirestore db,
  String path,
) async {
  final container = testContainer(database: db);
  addTearDown(container.dispose);
  testAuth(container).setSession(
    const AuthSession(
      uid: 'technician-demo',
      email: 'raka@example.test',
      role: UserRole.technician,
      verified: true,
    ),
  );
  container.read(appRouterProvider).go(path);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const BengkelKuApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapAction(
  WidgetTester tester,
  String label, {
  bool confirm = false,
}) async {
  final action = find.text(label);
  await reveal(tester, action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  if (confirm) {
    if (label == 'Ajukan selesai' &&
        find.byType(ServiceCompletionScreen).evaluate().isNotEmpty) {
      await tester.tap(find.text('Ajukan Selesai'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
  }
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
    'technician refinement captures actual dashboard list and task detail',
    (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = testContainer(database: await technicianFixture());
      addTearDown(container.dispose);
      testAuth(container).setSession(
        const AuthSession(
          uid: 'technician-demo',
          email: 'raka@example.test',
          role: UserRole.technician,
          verified: true,
        ),
      );
      final router = container.read(appRouterProvider);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: boundary, child: const BengkelKuApp()),
        ),
      );
      for (final (name, path) in [
        ('technician-dashboard', '/technician/home'),
        ('technician-tasks', '/technician/jobs'),
        ('technician-detail', '/technician/orders/task-active'),
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        await captureFixture(tester, boundary, 'refinement-$name');
        expect(tester.takeException(), isNull, reason: name);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'three technician screens reflow at phone widths and enlarged text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = await openTechnician(
        tester,
        await technicianFixture(),
        '/technician/home',
      );
      final router = container.read(appRouterProvider);
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.view.physicalSize = Size(width, 740);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          for (final route in ['home', 'jobs', 'orders/task-active']) {
            router.go('/technician/$route');
            await tester.pumpAndSettle();
            if (route == 'jobs') {
              await reveal(tester, find.byTooltip('Filter tugas'));
              await tester.tap(find.byTooltip('Filter tugas'));
              await tester.pumpAndSettle();
            }
            for (var i = 0; i < 6; i++) {
              await tester.drag(
                find.byType(Scrollable).first,
                const Offset(0, -300),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$width/$scale/$route',
              );
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('summary and searches stay scoped to the paginated own orders', (
    tester,
  ) async {
    final db = await technicianFixture();
    final historical = (await db.doc('serviceOrders/task-done-a').get())
        .data()!;
    for (var i = 0; i < 26; i++) {
      await db.doc('serviceOrders/old-$i').set({
        ...historical,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 10, i + 1)),
      });
    }
    final container = await openTechnician(tester, db, '/technician/home');
    expect(find.textContaining('Hari Ini'), findsNothing);
    final summary = find.byType(TechnicianSummary);
    expect(
      find.descendant(of: summary, matching: find.text('20')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('18')),
      findsOneWidget,
    );
    expect(find.textContaining('OTHER PRIVATE'), findsNothing);
    final router = container.read(appRouterProvider);
    router.go('/technician/jobs');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'n 4218');
    await tester.pumpAndSettle();
    expect(find.byType(TechnicianTaskCard), findsOneWidget);
    expect(find.text('task-active'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'old-0');
    await tester.pumpAndSettle();
    expect(find.text('Tugas belum ditemukan'), findsOneWidget);
    await tapAction(tester, 'Berikutnya');
    expect(find.text('Halaman 2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TechnicianTaskCard),
        matching: find.text('old-0'),
      ),
      findsOneWidget,
    );
    await reveal(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    tester.testTextInput.hide();
    await reveal(tester, find.byTooltip('Filter tugas'));
    await tester.tap(find.byTooltip('Filter tugas'));
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<ServiceOrderStatus>);
    await reveal(tester, dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai').last);
    await tester.pumpAndSettle();
    expect(find.byType(TechnicianTaskCard), findsNWidgets(10));
    await tapAction(tester, 'Sebelumnya');
    expect(find.text('Halaman 1'), findsOneWidget);
    expect(find.byType(TechnicianTaskCard), findsNWidgets(18));
    expect(find.textContaining('OTHER PRIVATE'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'technician can start pause resume submit complete and inspect the actual history',
    (tester) async {
      final db = await technicianFixture();
      await db.doc('serviceOrders/task-active').update({
        'status': 'assigned',
        'startedAt': null,
      });
      final container = await openTechnician(
        tester,
        db,
        '/technician/orders/task-active',
      );
      await tapAction(tester, 'Mulai pengerjaan');
      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(
        (await db.doc('serviceOrders/task-active').get())['status'],
        'assigned',
      );
      await tapAction(tester, 'Mulai pengerjaan', confirm: true);
      expect(
        (await db.doc('serviceOrders/task-active').get())['status'],
        'inProgress',
      );
      await tapAction(tester, 'Jeda pengerjaan', confirm: true);
      expect(
        (await db.doc('serviceOrders/task-active').get())['status'],
        'paused',
      );
      expect(find.text('Ajukan selesai'), findsNothing);
      await tapAction(tester, 'Lanjutkan pengerjaan', confirm: true);
      await tapAction(tester, 'Ajukan selesai', confirm: true);
      expect(
        (await db.doc('serviceOrders/task-active').get())['status'],
        'inProgress',
      );
      expect(find.textContaining('Lengkapi checklist'), findsWidgets);
      await tapAction(tester, 'Ubah checklist dan catatan');
      for (final label in [
        'Kondisi kendaraan diperiksa',
        'Keselamatan diperiksa',
        'Hasil pekerjaan diperiksa',
      ]) {
        final check = find.widgetWithText(CheckboxListTile, label);
        await reveal(tester, check);
        await tester.tap(check);
        await tester.pumpAndSettle();
      }
      await tapAction(tester, 'Diagnosis, tindakan dan catatan');
      for (final (label, value) in [
        ('Diagnosis', 'Dudukan mesin perlu disetel'),
        ('Tindakan', 'Penyetelan dan uji mesin'),
        ('Catatan', 'Uji jalan selesai'),
      ]) {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await reveal(tester, field);
        await tester.enterText(field, value);
      }
      await tapAction(tester, 'Simpan Checklist');
      await tapAction(tester, 'Ajukan Selesai', confirm: true);
      final awaiting = (await db.doc('serviceOrders/task-active').get())
          .data()!;
      expect(awaiting['status'], 'awaitingApproval');
      expect(find.text('Mulai pengerjaan'), findsNothing);
      expect(find.text('Ajukan selesai'), findsNothing);
      expect(find.text('Setujui penyelesaian'), findsNothing);
      final admin = FirestoreServiceOrderRepository(
        db,
        'admin-demo',
        UserRole.admin,
      );
      await admin.updateWork(
        'task-active',
        awaiting['revision'] as int,
        status: ServiceOrderStatus.completed,
        checklist: Map<String, bool>.from(awaiting['checklist'] as Map),
        diagnosis: awaiting['diagnosis'] as String,
        actions: awaiting['actions'] as String,
        notes: awaiting['notes'] as String,
      );
      await tester.pumpAndSettle();
      await tapAction(tester, 'Buka riwayat dan rincian biaya');
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/technician/history/task-active',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'quick parts action selects an eligible own task and posts the existing request form',
    (tester) async {
      final db = await technicianFixture();
      final container = await openTechnician(tester, db, '/technician/home');
      await tapAction(tester, 'Permintaan Sparepart');
      expect(find.textContaining('OTHER PRIVATE'), findsNothing);
      expect(find.byType(TechnicianTaskCard), findsNWidgets(2));
      await tester.tap(find.text('task-active').last);
      await tester.pumpAndSettle();
      expect(find.byType(PartRequestScreen), findsOneWidget);
      final sku = find.byType(TextFormField).first;
      expect(sku, findsOneWidget);
      await tester.enterText(sku, 'FILTER-UJI');
      await tester.enterText(find.byType(TextFormField).at(1), '2');
      final reason = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Alasan permintaan',
      );
      await reveal(tester, reason);
      await tester.enterText(reason, 'Penggantian saat pemeriksaan');
      await tapAction(tester, 'Ajukan Sparepart');
      final requests = await db
          .collection('serviceOrders/task-active/partRequests')
          .get();
      expect(requests.docs, hasLength(1));
      expect(requests.docs.single['sku'], 'FILTER-UJI');
      expect(requests.docs.single['status'], 'pending');
      expect(requests.docs.single['createdBy'], 'technician-demo');
      container.read(appRouterProvider).go('/technician/jobs');
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'all seven task statuses keep the right actions and block another technician detail',
    (tester) async {
      final db = await technicianFixture();
      final container = await openTechnician(
        tester,
        db,
        '/technician/orders/task-active',
      );
      for (final state in ServiceOrderStatus.values) {
        await db.doc('serviceOrders/task-active').update({
          'status': state.name,
        });
        await tester.pumpAndSettle();
        final buttons = <String>[
          if (state == ServiceOrderStatus.assigned) 'Mulai pengerjaan',
          if (state == ServiceOrderStatus.paused) 'Lanjutkan pengerjaan',
          if (state == ServiceOrderStatus.inProgress) ...[
            'Jeda pengerjaan',
            'Ajukan selesai',
          ],
        ];
        for (final label in [
          'Mulai pengerjaan',
          'Lanjutkan pengerjaan',
          'Jeda pengerjaan',
          'Ajukan selesai',
        ]) {
          if (buttons.contains(label)) {
            await reveal(tester, find.text(label));
            expect(find.text(label), findsOneWidget);
          } else {
            expect(find.text(label), findsNothing);
          }
        }
        expect(find.text('Setujui penyelesaian'), findsNothing);
        expect(tester.takeException(), isNull, reason: state.name);
      }
      container.read(appRouterProvider).go('/technician/orders/task-other');
      await tester.pumpAndSettle();
      expect(find.text('Tugas tidak dapat diakses'), findsOneWidget);
      expect(find.text('OTHER PRIVATE'), findsNothing);
      expect(find.text('Sparepart dan permintaan'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
