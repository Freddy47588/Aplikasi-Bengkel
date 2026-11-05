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
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/widgets/service_timeline.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/service_orders_screen.dart';
import 'package:bengkel_kendaraan/features/technician/presentation/technicians_screen.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/inventory_screen.dart';
import 'package:bengkel_kendaraan/features/inventory/presentation/order_parts_screen.dart';

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
  String name, {
  bool settle = true,
}) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(
    () => precacheImage(
      const AssetImage('assets/branding/emblem-mockup.png'),
      key.currentContext!,
    ),
  );
  await tester.runAsync(() async {
    for (final img in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(img.image, key.currentContext!);
    }
  });
  if (find.byType(Scrollable).evaluate().isNotEmpty) {
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  }
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final raster = await boundary.toImage(pixelRatio: 2);
    final bytes = await raster.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(
      const String.fromEnvironment(
        'CAPTURE_DIR',
        defaultValue: 'build/ui-ux-evidence',
      ),
    )..createSync(recursive: true);
    File(
      '${dir.path}/fixture-$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    raster.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'session splash has no actions or forced logout and follows authenticated role',
    (tester) async {
      final container = testContainer();
      addTearDown(container.dispose);
      testAuth(container).setSession(const AuthSession(loading: true));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(SessionSplash), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Keluar'), findsNothing);
      expect(
        (container.read(authRepositoryProvider) as FakeAuthRepository).calls,
        isEmpty,
      );
      testAuth(container).signIn(UserRole.technician);
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/technician/home',
      );
      expect(find.byType(SessionSplash), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'mockup alignment: all role screens reflow at 320dp and 200% text',
    (tester) async {
      final previousError = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        previousError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousError);
      viewport(tester, 320);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      final db = await fixtureDatabase();
      final container = testContainer(database: db);
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      for (final role in UserRole.values) {
        testAuth(container).signIn(role);
        for (final path in [
          'home',
          'profile',
          'orders',
          'orders/assigned',
          'history',
          if (role == UserRole.customer) ...['vehicles', 'booking', 'bookings'],
          if (role == UserRole.admin) ...[
            'technicians',
            'inventory',
            'invoices',
          ],
        ]) {
          router.go('/${role.name}/$path');
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${role.name}/$path top',
          );
          if (find.byType(ListView).evaluate().isNotEmpty) {
            for (var n = 0; n < 18; n++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -400),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${role.name}/$path scroll $n',
              );
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'mockup alignment: current and stopped work have distinct progress and actions',
    (tester) async {
      for (final state in ServiceOrderStatus.values) {
        final order = ServiceOrder('test', {
          'status': state.name,
          'technicianId': 't',
          'startedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 4)),
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: ServiceTimeline(order: order)),
          ),
        );
        if (state == ServiceOrderStatus.cancelled) {
          expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
          expect(find.textContaining('Proses berhenti'), findsOneWidget);
        } else if (state != ServiceOrderStatus.completed) {
          expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      expect(
        workActionLabel(
          ServiceOrderStatus.inProgress,
          ServiceOrderStatus.paused,
        ),
        'Lanjutkan pengerjaan',
      );
      expect(
        workActionLabel(
          ServiceOrderStatus.assigned,
          ServiceOrderStatus.awaitingApproval,
        ),
        'Kembalikan untuk perbaikan',
      );
      expect(
        workActionLabel(
          ServiceOrderStatus.awaitingApproval,
          ServiceOrderStatus.inProgress,
        ),
        'Ajukan selesai',
      );
    },
  );

  testWidgets(
    'mockup alignment: capture actual Flutter screens with test fixtures',
    (tester) async {
      if (!const bool.fromEnvironment('CAPTURE_UI')) return;
      viewport(tester, 390);
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      final db = await fixtureDatabase();
      final container = testContainer(
        database: db,
        bookings: Stream.value([
          Booking(
            id: 'visual-booking',
            customerId: 'customer-demo',
            draft: BookingDraft(
              vehicleId: 'brio',
              service: 'Ganti Oli',
              scheduledAt: DateTime.utc(2026, 11, 5, 2),
              complaint: 'Suara mesin saat berkendara',
            ),
          ),
        ]),
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      final key = GlobalKey();
      final orderData = (await db.doc('serviceOrders/assigned').get()).data()!;
      await db.doc('serviceOrders/completed').set({
        ...orderData,
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'laborPrice': 150000,
        'diagnosis': 'Oli mesin perlu diganti.',
        'actions': 'Penggantian oli mesin.',
      });
      await db.doc('invoices/completed').set({
        'customerId': 'customer-demo',
        'invoiceNo': 'INV-TEST-001',
        'status': 'partial',
        'vehiclePlate': 'B 1234 XYZ',
        'serviceName': 'Ganti Oli',
        'createdAt': Timestamp.now(),
        'laborPrice': 150000,
        'parts': [],
        'subtotal': 150000,
        'discount': 0,
        'fee': 0,
        'grandTotal': 150000,
        'paidAmount': 100000,
        'change': 0,
        'due': 50000,
      });
      await db.doc('technicians/technician-demo').set({
        'name': 'Ari',
        'specialization': 'Mesin',
        'active': true,
        'available': true,
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(key: key, child: const BengkelKuApp()),
        ),
      );
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'alignment-login');
      await reveal(tester, find.text('Daftar akun pelanggan'));
      await tester.tap(find.text('Daftar akun pelanggan'));
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'alignment-register');
      await reveal(tester, find.text('Sudah punya akun? Masuk'));
      await tester.tap(find.text('Sudah punya akun? Masuk'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byType(TextFormField).first);
      await tester.enterText(
        find.byType(TextFormField).first,
        'customer@example.test',
      );
      await reveal(tester, find.text('Lupa kata sandi'));
      await tester.tap(find.text('Lupa kata sandi'));
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'alignment-password-reset');
      await reveal(tester, find.text('Kirim Tautan'));
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'alignment-password-reset-sent');
      testAuth(container).setSession(const AuthSession(loading: true));
      await tester.pump();
      await captureFixture(tester, key, 'alignment-splash', settle: false);
      testAuth(container).setSession(
        const AuthSession(
          uid: 'customer-demo',
          email: 'pelanggan@example.test',
          role: UserRole.customer,
        ),
      );
      await tester.pumpAndSettle();
      await captureFixture(tester, key, 'alignment-verification');
      for (final role in UserRole.values) {
        testAuth(container).setSession(
          AuthSession(
            uid: '${role.name}-demo',
            role: role,
            verified: true,
            email: '${role.name}@example.test',
          ),
        );
        for (final path in [
          'home',
          'profile',
          'orders',
          'orders/assigned',
          'history/completed',
          if (role == UserRole.customer) ...['vehicles', 'booking'],
          if (role != UserRole.technician) ...[
            'bookings',
            'bookings/visual-booking',
          ],
          if (role == UserRole.admin) ...[
            'technicians',
            'inventory',
            'invoices',
            'invoices/completed',
          ],
        ]) {
          router.go('/${role.name}/$path');
          await tester.pumpAndSettle();
          await captureFixture(
            tester,
            key,
            'alignment-${role.name}-${path.replaceAll('/', '-')}',
          );
          expect(tester.takeException(), isNull);
        }
      }
      for (final entry in <String, Widget>{
        'checklist': WorkEditor(order: ServiceOrder('assigned', orderData)),
        'request-part': const PartRequestScreen(orderId: 'assigned'),
        'part-detail': const SparepartDetailScreen(sku: 'OIL'),
        'part-editor': const SparepartEditor(),
        'stock-operation': const StockOperationScreen(sku: 'OIL'),
        'technician-editor': const TechnicianEditor(),
      }.entries) {
        testAuth(container).signIn(UserRole.admin);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                home: entry.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await captureFixture(tester, key, 'alignment-${entry.key}');
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
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
    expect(find.text('Aplikasi Manajemen Bengkel'), findsOneWidget);
    expect(
      find.textContaining(RegExp('freddy|zaki|edition', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('Coba lagi')),
      alignment: 0.5,
    );
    await tester.pump(const Duration(milliseconds: 100));
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
        await reveal(tester, find.text('Masuk dengan Email'));
        await tester.tap(find.text('Masuk dengan Email'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Email tidak valid.'));
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
