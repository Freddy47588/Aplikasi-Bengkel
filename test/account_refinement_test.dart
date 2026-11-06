import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'ui_ux_polish_test.dart' show captureFixture;

const pendingAccount = AuthSession(
  uid: 'account-test',
  email: 'akun.uji@example.test',
  role: UserRole.customer,
);
const verifiedAccount = AuthSession(
  uid: 'account-test',
  email: 'akun.uji@example.test',
  role: UserRole.customer,
  verified: true,
);

Future<({ProviderContainer container, FakeAuthRepository repo})> openAccount(
  WidgetTester tester,
  AuthSession session, {
  GlobalKey? boundary,
}) async {
  final repo = FakeAuthRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(repo.changes.close);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(key: boundary, child: const BengkelKuApp()),
    ),
  );
  repo.changes.add(session);
  await tester.pumpAndSettle();
  return (container: container, repo: repo);
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
    'recovery validates email prevents duplicates and returns safely',
    (tester) async {
      final h = await openAccount(tester, const AuthSession());
      await reveal(tester, find.text('Lupa kata sandi'));
      await tester.tap(find.text('Lupa kata sandi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'invalid@');
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Isi email yang valid untuk reset kata sandi.'),
        findsOneWidget,
      );
      expect(h.repo.calls, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'akun.uji@example.test',
      );
      h.repo.pending = Completer<void>();
      await tester.tap(find.text('Kirim Tautan'));
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pump();
      expect(h.repo.calls, ['reset:akun.uji@example.test']);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      h.repo.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
      h.repo.pending = null;
      h.repo.failure = FirebaseAuthException(code: 'network-request-failed');
      await tester.tap(find.text('Kirim Tautan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Jaringan terputus. Periksa koneksi Anda.'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Lupa Password?'), findsNothing);
      expect(find.text('Masuk dengan Email'), findsOneWidget);
    },
  );

  testWidgets(
    'verification resend refresh lifecycle and inactive guard remain enforced',
    (tester) async {
      final h = await openAccount(tester, pendingAccount);
      final router = h.container.read(appRouterProvider);
      router.go('/customer/vehicles');
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/account');
      h.repo.pending = Completer<void>();
      await reveal(tester, find.text('Kirim Ulang'));
      await tester.tap(find.text('Kirim Ulang'));
      await tester.tap(find.text('Kirim Ulang'));
      await tester.pump();
      expect(h.repo.calls, ['verify']);
      h.repo.pending!.complete();
      await tester.pumpAndSettle();
      h.repo.pending = null;
      h.repo.failure = FirebaseAuthException(code: 'too-many-requests');
      await reveal(tester, find.text('Kirim Ulang'));
      await tester.tap(find.text('Kirim Ulang'));
      await tester.pumpAndSettle();
      await reveal(
        tester,
        find.text('Terlalu banyak percobaan. Coba lagi nanti.'),
      );
      expect(
        find.text('Terlalu banyak percobaan. Coba lagi nanti.'),
        findsOneWidget,
      );
      h.repo.failure = null;
      await reveal(tester, find.text('Periksa ulang status akun'));
      await tester.tap(find.text('Periksa ulang status akun'));
      await tester.pumpAndSettle();
      expect(h.repo.calls.last, 'refresh');
      final beforeRefresh = h.repo.calls.where((v) => v == 'refresh').length;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pumpAndSettle();
      }
      expect(
        h.repo.calls.where((v) => v == 'refresh'),
        hasLength(greaterThan(beforeRefresh)),
      );
      h.repo.changes.add(
        const AuthSession(
          uid: 'account-test',
          email: 'akun.uji@example.test',
          role: UserRole.customer,
          verified: true,
          active: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Akun dinonaktifkan. Hubungi pengelola bengkel.'),
        findsOneWidget,
      );
      expect(find.text('Kirim Ulang'), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/account');
      h.repo.changes.add(verifiedAccount);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/customer/home');
    },
  );

  testWidgets(
    'profile uses session identity reset refresh logout and role redirects',
    (tester) async {
      final h = await openAccount(tester, verifiedAccount);
      final router = h.container.read(appRouterProvider);
      for (final role in UserRole.values) {
        h.repo.changes.add(
          AuthSession(
            uid: 'account-test',
            email: 'akun.uji@example.test',
            role: role,
            verified: true,
          ),
        );
        await tester.pumpAndSettle();
        router.go('/${role.name}/profile');
        await tester.pumpAndSettle();
        expect(find.text('Akun ${role.label}'), findsOneWidget);
        await reveal(tester, find.text('Informasi Akun'));
        await tester.tap(find.text('Informasi Akun'));
        await tester.pumpAndSettle();
        expect(find.text('Peran: ${role.label}'), findsOneWidget);
        await reveal(tester, find.text('Ubah Password'));
        await tester.tap(find.text('Ubah Password'));
        await tester.pumpAndSettle();
        expect(h.repo.calls.last, 'reset:akun.uji@example.test');
        await reveal(tester, find.text('Verifikasi Email'));
        await tester.tap(find.text('Verifikasi Email'));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('Periksa ulang status akun'));
        await tester.tap(find.text('Periksa ulang status akun'));
        await tester.pumpAndSettle();
        expect(h.repo.calls.last, 'refresh');
        router.go('/${role.name == 'customer' ? 'admin' : 'customer'}/profile');
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          '/${role.name}/home',
        );
      }
      router.go('/${UserRole.values.last.name}/profile');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Keluar Akun'));
      await tester.tap(find.text('Keluar Akun'));
      await tester.pumpAndSettle();
      expect(h.repo.calls.last, 'logout');
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'account screens reflow with keyboard expanded details and enlarged text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final h = await openAccount(tester, const AuthSession());
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        for (final scale in [1.0, 1.3, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          h.repo.changes.add(const AuthSession());
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Lupa kata sandi'));
          await tester.tap(find.text('Lupa kata sandi'));
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 280);
          await tester.tap(find.byType(TextFormField));
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Kirim Tautan'));
          expect(
            tester.takeException(),
            isNull,
            reason: 'recovery $width/$scale keyboard',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          tester.view.resetViewInsets();
          h.repo.changes.add(pendingAccount);
          await tester.pumpAndSettle();
          await reveal(tester, find.text('Periksa ulang status akun'));
          expect(
            tester.takeException(),
            isNull,
            reason: 'verification $width/$scale',
          );
          h.repo.changes.add(verifiedAccount);
          await tester.pumpAndSettle();
          h.container.read(appRouterProvider).go('/customer/profile');
          await tester.pumpAndSettle();
          for (final label in [
            'Informasi Akun',
            'Verifikasi Email',
            'Garasi & dokumen',
          ]) {
            await reveal(tester, find.text(label));
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
          }
          await reveal(tester, find.text('Keluar Akun'));
          expect(
            tester.takeException(),
            isNull,
            reason: 'profile $width/$scale expanded',
          );
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('account refinement captures recovery verification and profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    final harness = await openAccount(
      tester,
      const AuthSession(),
      boundary: boundary,
    );
    await reveal(tester, find.text('Lupa kata sandi'));
    await tester.tap(find.text('Lupa kata sandi'));
    await tester.pumpAndSettle();
    await captureFixture(tester, boundary, 'account-recovery');
    harness.repo.changes.add(pendingAccount);
    await tester.pumpAndSettle();
    await captureFixture(tester, boundary, 'account-verification');
    harness.repo.changes.add(verifiedAccount);
    await tester.pumpAndSettle();
    harness.container.read(appRouterProvider).go('/customer/profile');
    await tester.pumpAndSettle();
    await captureFixture(tester, boundary, 'account-profile');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
