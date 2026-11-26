import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/app/theme/app_theme.dart';
import 'package:bengkel_kendaraan/core/widgets/mobile_navigation.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('friendlyWorkshopError maps technical errors to clean Indonesian', () {
    expect(
      friendlyWorkshopError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('tidak memiliki izin'),
    );
    expect(
      friendlyWorkshopError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
      contains('koneksi internet'),
    );
    expect(
      friendlyWorkshopError(StateError('Slot waktu sudah dipesan.')),
      'Slot waktu sudah dipesan.',
    );
    expect(
      friendlyWorkshopError(
        StateError('Bad state: Exception in package:bengkel/foo.dart'),
      ),
      isNot(contains('package:')),
    );
    expect(
      friendlyWorkshopError(const FormatException('unexpected char')),
      contains('Format data'),
    );
    expect(
      friendlyWorkshopError(Exception('Raw internal Dart stack info')),
      isNot(contains('Raw internal')),
    );
  });

  test('navigationIndex maps 3 roles cleanly across nested routes', () {
    expect(navigationIndex('customer', '/customer/home'), 0);
    expect(navigationIndex('customer', '/customer/booking'), 1);
    expect(navigationIndex('customer', '/customer/bookings/bk-1'), 1);
    expect(navigationIndex('customer', '/customer/orders/so-1'), 2);
    expect(navigationIndex('customer', '/customer/invoices'), 2);
    expect(navigationIndex('customer', '/customer/vehicles'), 3);
    expect(navigationIndex('customer', '/customer/profile'), 3);

    expect(navigationIndex('admin', '/admin/home'), 0);
    expect(navigationIndex('admin', '/admin/bookings'), 1);
    expect(navigationIndex('admin', '/admin/orders/so-1'), 1);
    expect(navigationIndex('admin', '/admin/technicians'), 1);
    expect(navigationIndex('admin', '/admin/inventory'), 2);
    expect(navigationIndex('admin', '/admin/invoices'), 3);
    expect(navigationIndex('admin', '/admin/profile'), 4);

    expect(navigationIndex('technician', '/technician/home'), 0);
    expect(navigationIndex('technician', '/technician/jobs'), 1);
    expect(navigationIndex('technician', '/technician/orders/so-1'), 1);
    expect(navigationIndex('technician', '/technician/history'), 2);
    expect(navigationIndex('technician', '/technician/profile'), 3);
  });

  testWidgets(
    'MobileNavigation renders without overflow at 320dp with 200% text scaling',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      for (final (role, path, activeLabel) in [
        ('customer', '/customer/home', 'Beranda'),
        ('admin', '/admin/inventory', 'Stok'),
        ('admin', '/admin/invoices', 'Kasir'),
        ('technician', '/technician/jobs', 'Tugas'),
      ]) {
        final router = GoRouter(
          initialLocation: path,
          routes: [
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: MobileNavigation(role: role),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
        );
        await tester.pumpAndSettle();

        expect(find.text(activeLabel), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '$role at $path with 200% text on 320dp',
        );
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Crisp design system components render cleanly at 320dp and 200% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      String selected = 'progres';

      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: WorkshopBody(
              showWave: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const BrandLockup(),
                  CarbonSpotlightCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Honda Vario 160',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 6),
                                  IndonesianPlateBadge(
                                    plate: 'N 4821 AB',
                                    dark: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const UniversalVehicleThumb(
                              kind: 'motorcycle',
                              darkSurface: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const ServiceProgressStrip(
                          activeStep: 3,
                          labels: [
                            'Konfirmasi',
                            'Teknisi',
                            'Pengerjaan',
                            'Selesai',
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const IndonesianPlateBadge(plate: 'N 1904 CD'),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      UniversalVehicleThumb(vehicleName: 'Honda Beat'),
                      UniversalVehicleThumb(kind: 'car'),
                      QuickServiceIcon(QuickServiceKind.periodic),
                      QuickServiceIcon(QuickServiceKind.oil),
                      QuickServiceIcon(QuickServiceKind.brake),
                      QuickServiceIcon(QuickServiceKind.electric),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setState) => WorkshopSegmentedTabs<String>(
                      items: const [
                        ('progres', 'Progres'),
                        ('riwayat', 'Riwayat'),
                        ('invoice', 'Invoice'),
                      ],
                      selected: selected,
                      onSelected: (v) => setState(() => selected = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Smart Workshop Management'), findsOneWidget);
      expect(find.text('N 4821 AB'), findsOneWidget);
      expect(find.byType(WorkshopWave), findsNothing);
      expect(AppColors.secondary, const Color(0xFFEA580C));
      await tester.scrollUntilVisible(
        find.text('N 1904 CD'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('N 1904 CD'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Invoice'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Invoice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
