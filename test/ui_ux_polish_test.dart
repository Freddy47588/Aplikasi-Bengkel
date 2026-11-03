import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/app/theme/app_theme.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/models/invoice.dart';
import 'package:bengkel_kendaraan/core/widgets/history_payment_summary.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';

void viewport(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 740);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<FakeFirebaseFirestore> fixtureDatabase() async {
  final db = FakeFirebaseFirestore();
  await db.doc('serviceOrders/assigned').set({
    'status': 'assigned',
    'revision': 1,
    'customerId': 'customer-demo',
    'technicianId': 'technician-demo',
    'technicianName': 'Ari',
    'vehicleName': 'Honda Brio RS',
    'vehiclePlate': 'B 1234 XYZ',
    'vehicleId': 'brio',
    'serviceId': 'oil',
    'serviceName': 'Ganti Oli',
    'complaint': 'Suara mesin saat berkendara',
    'checklist': {
      'vehicleChecked': false,
      'safetyChecked': false,
      'workChecked': false,
    },
    'diagnosis': '',
    'actions': '',
    'notes': '',
    'createdAt': Timestamp.now(),
  });
  await db.doc('spareparts/OIL').set({
    'sku': 'OIL',
    'name': 'Oli Mesin',
    'category': 'Pelumas',
    'unit': 'liter',
    'supplier': '',
    'buyPrice': 35000,
    'sellPrice': 50000,
    'minimumStock': 3,
    'stock': 1,
    'lowStock': true,
    'active': true,
    'version': 0,
  });
  return db;
}

// Optional real Flutter raster output with explicit test fixtures, never a
// substitute for authenticated emulator/device evidence.
Future<void> captureFixture(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/branding/emblem.png'),
      key.currentContext!,
    ),
  );
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final raster = await boundary.toImage(pixelRatio: 2);
    final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/ui-ux-evidence')..createSync(recursive: true);
    File(
      '${dir.path}/fixture-$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    raster.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('universal blue identity and state feedback fit 320dp at 1.3x', (
    tester,
  ) async {
    viewport(tester, 320);
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: WorkshopBody(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const BrandLockup(),
                const LoadingState(),
                LoadError(onRetry: () => retried = true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('BengkelKu'), findsOneWidget);
    expect(find.text('Perawatan kendaraan Anda'), findsOneWidget);
    expect(
      find.textContaining(RegExp('freddy|zaki|edition', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    expect(retried, isTrue);
    final scheme = Theme.of(
      tester.element(find.byType(BrandLockup)),
    ).colorScheme;
    expect(scheme.primary, AppColors.secondary);
    expect(AppColors.primary, const Color(0xFF1E3A5F));
    expect(AppColors.secondary, const Color(0xFF2563EB));
    expect(AppColors.accent, const Color(0xFFF59E0B));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    // Use the SDK's actual Roboto/Material fonts for reviewable raster output.
    // Normal regression tests retain Flutter's stricter Ahem metrics.
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
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
    ]) {
      roboto.addFont(
        File.fromUri(
          fonts.resolve(name),
        ).readAsBytes().then(ByteData.sublistView),
      );
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File.fromUri(
          fonts.resolve('materialicons-regular.otf'),
        ).readAsBytes().then(ByteData.sublistView),
      );
    await icons.load();
  });
  for (final width in [320.0, 360.0, 390.0, 430.0, 800.0]) {
    for (final role in UserRole.values) {
      testWidgets(
        '${role.name} dashboard $width dp at 1.3x renders data, scrolls, and opens role actions',
        (tester) async {
          viewport(tester, width);
          final db = await fixtureDatabase();
          final container = testContainer(database: db);
          addTearDown(container.dispose);
          testAuth(container).setSession(
            AuthSession(
              uid: '${role.name}-demo',
              email: 'pelanggan@example.test',
              role: role,
              verified: true,
            ),
          );
          final router = container.read(appRouterProvider)
            ..go('/${role.name}/home');
          final boundary = GlobalKey();
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: boundary,
                child: const BengkelKuApp(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Halo, pelanggan'), findsOneWidget);
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            0,
          );
          if (width == 390) {
            await captureFixture(
              tester,
              boundary,
              '${role.name}-dashboard-390',
            );
          }
          final action = role == UserRole.customer
              ? 'Booking Servis'
              : role == UserRole.admin
              ? 'Kelola Booking'
              : 'Pekerjaan Saya';
          await tester.scrollUntilVisible(
            find.text(action),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(action));
          await tester.pumpAndSettle();
          expect(
            router.routeInformationProvider.value.uri.path,
            '/${role.name}/${role == UserRole.customer
                ? 'booking'
                : role == UserRole.admin
                ? 'bookings'
                : 'jobs'}',
          );
          expect(
            tester
                .widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            1,
          );
          expect(tester.takeException(), isNull);
          router.go('/${role.name}/home');
          await tester.pumpAndSettle();
          for (var i = 0; i < 18; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -350),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final width in [320.0, 390.0]) {
    for (final role in UserRole.values) {
      testWidgets(
        '${role.name} secondary screens at $width dp and 1.3x preserve navigation',
        (tester) async {
          viewport(tester, width);
          final db = await fixtureDatabase();
          final container = testContainer(database: db);
          addTearDown(container.dispose);
          testAuth(container).signIn(role);
          final router = container.read(appRouterProvider);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const BengkelKuApp(),
            ),
          );
          final routes = <String, int>{
            'profile': 3,
            'history': role == UserRole.admin ? 2 : 2,
            'orders': role == UserRole.admin
                ? 2
                : role == UserRole.customer
                ? 2
                : 1,
            if (role == UserRole.customer) ...{'vehicles': 3, 'bookings': 1},
            if (role != UserRole.technician) 'invoices': 2,
            if (role == UserRole.admin) ...{'inventory': 2, 'technicians': 2},
          };
          for (final entry in routes.entries) {
            router.go('/${role.name}/${entry.key}');
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<NavigationBar>(find.byType(NavigationBar))
                  .selectedIndex,
              entry.value,
              reason: '${role.name}/${entry.key}',
            );
            if (find.byType(ListView).evaluate().isNotEmpty) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -600),
              );
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '${role.name}/${entry.key}',
            );
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
    testWidgets(
      'login $width dp at 1.3x supports keyboard, validation and password visibility',
      (tester) async {
        viewport(tester, width);
        final container = testContainer();
        addTearDown(container.dispose);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(key: boundary, child: const BengkelKuApp()),
          ),
        );
        await tester.pumpAndSettle();
        if (width == 390) await captureFixture(tester, boundary, 'login-390');
        await tester.ensureVisible(find.text('Masuk dengan Email'));
        await tester.tap(find.text('Masuk dengan Email'));
        await tester.pumpAndSettle();
        expect(find.text('Email tidak valid.'), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('Tampilkan kata sandi'));
        await tester.tap(find.byTooltip('Tampilkan kata sandi'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .obscureText,
          false,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        await tester.enterText(find.byType(TextFormField).last, 'password123');
        await tester.ensureVisible(find.text('Masuk dengan Email'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('dashboard counts reflect bookings rather than invented totals', (
    tester,
  ) async {
    final source = StreamController<List<Booking>>();
    final container = testContainer(bookings: source.stream);
    addTearDown(() async {
      container.dispose();
      await source.close();
    });
    testAuth(container).signIn(UserRole.customer);
    container.read(appRouterProvider).go('/customer/home');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BengkelKuApp(),
      ),
    );
    await tester.pump();
    source.add([
      Booking(
        id: 'b',
        customerId: 'customer-demo',
        draft: BookingDraft(
          vehicleId: 'brio',
          service: 'Ganti Oli',
          scheduledAt: DateTime(2030),
          complaint: 'Mesin bising',
        ),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(container.read(bookingsProvider).requireValue.length, 1);
    await tester.scrollUntilVisible(
      find.text('Booking aktif'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    final card = find.ancestor(
      of: find.text('Booking aktif'),
      matching: find.byType(Card),
    );
    expect(find.descendant(of: card, matching: find.text('1')), findsOneWidget);
    source.add([]);
    await tester.pumpAndSettle();
    expect(find.descendant(of: card, matching: find.text('0')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'history invoice status updates in realtime and technician never queries invoices',
    (tester) async {
      final db = await fixtureDatabase();
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      testAuth(container).signIn(UserRole.customer);
      await db.doc('invoices/assigned').set({'status': 'unpaid'});
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HistoryPaymentSummary(orderId: 'assigned')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Belum dibayar'), findsOneWidget);
      await db.doc('invoices/assigned').update({'status': 'paid'});
      await tester.pumpAndSettle();
      expect(find.text('Lunas'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      final technician = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          historyInvoiceStatusProvider('assigned').overrideWith(
            (ref) => throw StateError('Technician must not read invoice'),
          ),
        ],
      );
      addTearDown(technician.dispose);
      testAuth(technician).signIn(UserRole.technician);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: technician,
          child: const MaterialApp(
            home: Scaffold(body: HistoryPaymentSummary(orderId: 'assigned')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pembayaran dikelola admin/kasir.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('history payment cache never implies server freshness', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(TestAuthController.new),
        historyInvoiceStatusProvider('so').overrideWith(
          (ref) => Stream.value((
            invoice: Invoice('so', {'status': 'paid'}),
            cached: true,
          )),
        ),
      ],
    );
    addTearDown(container.dispose);
    testAuth(container).signIn(UserRole.customer);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: HistoryPaymentSummary(orderId: 'so')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline/cache:'), findsOneWidget);
    expect(find.text('Lunas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('auxiliary route destinations preserve the visible product area', () {
    expect(navigationIndex('customer', '/customer/bookings/a'), 1);
    expect(navigationIndex('customer', '/customer/orders/a'), 2);
    expect(navigationIndex('customer', '/customer/vehicles'), 3);
    expect(navigationIndex('admin', '/admin/inventory'), 2);
    expect(navigationIndex('admin', '/admin/invoices/a'), 2);
    expect(navigationIndex('technician', '/technician/orders/a'), 1);
  });
}
