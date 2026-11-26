import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/widgets/session_splash.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  const captureEnabled = bool.fromEnvironment('CAPTURE_UI');

  setUpAll(() async {
    if (!captureEnabled) return;
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
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File.fromUri(
          fonts.resolve('MaterialIcons-Regular.otf'),
        ).readAsBytes().then(ByteData.sublistView),
      );
    await icons.load();
  });

  testWidgets('capture crisp automotive showcase screenshots', (tester) async {
    if (!captureEnabled) return;

    const size = Size(390, 844);
    const ratio = 2.0;
    tester.view.physicalSize = size * ratio;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final outDir = Directory('docs/screenshots/crisp-automotive')
      ..createSync(recursive: true);

    Future<void> snap(GlobalKey key, String filename) async {
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/branding/logo_v2.png',
          'assets/illustrations/splash_everyday.jpg',
          'assets/illustrations/vehicle_motor.png',
          'assets/illustrations/vehicle_car.png',
        ]) {
          await precacheImage(AssetImage(asset), key.currentContext!);
        }
        for (final img in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(img.image, key.currentContext!);
        }
      });
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: ratio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '${outDir.path}/$filename',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    // 1. Splash
    final splashKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: splashKey,
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SessionSplash(),
        ),
      ),
    );
    await snap(splashKey, '01_splash.png');

    // Seed realistic workshop data
    final db = FakeFirebaseFirestore();
    final now = DateTime.now();
    await db.doc('vehicles/v1').set({
      'ownerId': 'customer-demo',
      'name': 'Yamaha NMAX 155 Turbo',
      'plate': 'N 4821 ABG',
      'kind': 'motorcycle',
      'notes': 'Servis rutin tiap 2.500 km',
      'active': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await db.doc('vehicles/v2').set({
      'ownerId': 'customer-demo',
      'name': 'Honda HR-V 1.5 E CVT',
      'plate': 'N 1924 EAX',
      'kind': 'car',
      'notes': 'Putih Mutiara 2024',
      'active': true,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await db.doc('services/s1').set({
      'name': 'Servis Berkala 10.000 KM',
      'active': true,
    });
    await db.doc('services/s2').set({
      'name': 'Ganti Oli Mesin & Filter',
      'active': true,
    });
    await db.doc('bookings/BKG-2026-08').set({
      'customerId': 'customer-demo',
      'vehicleId': 'v2',
      'vehicleName': 'Honda HR-V 1.5 E CVT',
      'vehiclePlate': 'N 1924 EAX',
      'serviceId': 's2',
      'serviceName': 'Ganti Oli Mesin & Filter',
      'scheduledAt': Timestamp.fromDate(
        DateTime(now.year, now.month, now.day + 1, 10),
      ),
      'complaint': 'Tarikan awal agak berat dan ganti oli rutin.',
      'status': 'pending',
      'slotId': 'slot-1',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await db.doc('technicians/technician-demo').set({
      'name': 'Andi Pratama',
      'specialization': 'Mesin & Injeksi',
      'active': true,
      'available': false,
      'currentOrderId': 'SO-2026-014',
    });
    await db.doc('serviceOrders/SO-2026-014').set({
      'bookingId': 'BKG-2026-07',
      'customerId': 'customer-demo',
      'technicianId': 'technician-demo',
      'technicianName': 'Andi Pratama',
      'vehicleId': 'v1',
      'vehicleName': 'Yamaha NMAX 155 Turbo',
      'vehiclePlate': 'N 4821 ABG',
      'serviceId': 's1',
      'serviceName': 'Servis Berkala 10.000 KM',
      'complaint': 'Cek CVT, bersihkan throttle body, dan ganti oli gardan.',
      'status': 'inProgress',
      'revision': 2,
      'checklist': {
        'vehicleChecked': true,
        'safetyChecked': true,
        'workChecked': false,
      },
      'diagnosis': 'V-belt masih baik, roller sedikit aus.',
      'actions': 'Pembersihan CVT & throttle body sedang berlangsung.',
      'notes': 'Estimasi selesai pukul 14:30 WIB.',
      'laborPrice': 85000,
      'scheduledAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'startedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await db.doc('serviceOrders/SO-2026-013').set({
      'bookingId': 'BKG-2026-06',
      'customerId': 'customer-demo',
      'technicianId': 'technician-demo',
      'technicianName': 'Andi Pratama',
      'vehicleId': 'v2',
      'vehicleName': 'Honda HR-V 1.5 E CVT',
      'vehiclePlate': 'N 1924 EAX',
      'serviceId': 's1',
      'serviceName': 'Tune Up & Uji Rem',
      'complaint': 'Rem sedikit berdecit saat hujan.',
      'status': 'awaitingApproval',
      'revision': 3,
      'checklist': {
        'vehicleChecked': true,
        'safetyChecked': true,
        'workChecked': true,
      },
      'diagnosis': 'Kampas rem depan kotor, piringan normal.',
      'actions': 'Kampas rem dibersihkan dan rem disetel ulang.',
      'notes': 'Menunggu verifikasi akhir Admin.',
      'laborPrice': 150000,
      'scheduledAt': Timestamp.now(),
      'createdAt': Timestamp.now(),
      'startedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    await db.doc('serviceOrders/SO-2026-011').set({
      'bookingId': 'BKG-2026-04',
      'customerId': 'customer-demo',
      'technicianId': 'technician-demo',
      'technicianName': 'Andi Pratama',
      'vehicleId': 'v1',
      'vehicleName': 'Yamaha NMAX 155 Turbo',
      'vehiclePlate': 'N 4821 ABG',
      'serviceId': 's2',
      'serviceName': 'Ganti Oli Mesin & Filter',
      'complaint': 'Jadwal rutin.',
      'status': 'completed',
      'revision': 4,
      'laborPrice': 60000,
      'completedAt': Timestamp.now(),
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
    });
    await db.doc('spareparts/OLI-YAM-1L').set({
      'sku': 'OLI-YAM-1L',
      'name': 'Oli Yamalube Super Matic 1L',
      'category': 'Pelumas',
      'unit': 'botol',
      'supplier': 'PT Surya Motor Part',
      'buyPrice': 52000,
      'sellPrice': 75000,
      'minimumStock': 5,
      'stock': 2,
      'lowStock': true,
      'active': true,
      'version': 1,
    });
    await db.doc('spareparts/FIL-UDR-02').set({
      'sku': 'FIL-UDR-02',
      'name': 'Filter Udara Yamaha NMAX',
      'category': 'Filter',
      'unit': 'pcs',
      'supplier': 'PT Surya Motor Part',
      'buyPrice': 38000,
      'sellPrice': 58000,
      'minimumStock': 4,
      'stock': 14,
      'lowStock': false,
      'active': true,
      'version': 1,
    });
    await db.doc('invoices/SO-2026-011').set({
      'invoiceNo': 'INV-2026-011',
      'serviceOrderId': 'SO-2026-011',
      'customerId': 'customer-demo',
      'vehiclePlate': 'N 4821 ABG',
      'serviceName': 'Ganti Oli Mesin & Filter',
      'laborPrice': 60000,
      'subtotal': 135000,
      'discount': 0,
      'fee': 0,
      'grandTotal': 135000,
      'paidAmount': 135000,
      'due': 0,
      'status': 'paid',
      'method': 'cash',
      'revision': 1,
      'createdAt': Timestamp.now(),
      'paidAt': Timestamp.now(),
    });

    final container = testContainer(database: db);
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    final appKey = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(key: appKey, child: const BengkelKuApp()),
      ),
    );

    // 2. Login
    await snap(appKey, '02_login.png');

    // 3–5 & 12 Customer screens
    testAuth(container).signIn(UserRole.customer);
    for (final (route, file) in [
      ('/customer/home', '03_customer_home.png'),
      ('/customer/booking', '04_customer_booking.png'),
      ('/customer/vehicles', '05_customer_vehicles.png'),
      ('/customer/profile', '12_profile.png'),
    ]) {
      router.go(route);
      await snap(appKey, file);
    }

    // 6–9 Admin screens
    testAuth(container).signIn(UserRole.admin);
    for (final (route, file) in [
      ('/admin/home', '06_admin_home.png'),
      ('/admin/orders', '07_admin_orders.png'),
      ('/admin/inventory', '08_admin_inventory.png'),
      ('/admin/invoices', '09_admin_payments.png'),
    ]) {
      router.go(route);
      await snap(appKey, file);
    }

    // 10–11 Technician screens
    testAuth(container).signIn(UserRole.technician);
    for (final (route, file) in [
      ('/technician/home', '10_technician_home.png'),
      ('/technician/jobs', '11_technician_jobs.png'),
    ]) {
      router.go(route);
      await snap(appKey, file);
    }

    await tester.pumpWidget(const SizedBox());
  });
}
