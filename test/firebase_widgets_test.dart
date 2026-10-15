import 'dart:async';
import 'package:bengkel_kendaraan/app/app.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firebase_providers.dart';
import 'package:bengkel_kendaraan/features/auth/presentation/login_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_support.dart';
import 'package:bengkel_kendaraan/core/widgets/logout_button.dart';

void main() {
  testWidgets('logout disables duplicate requests and reports errors', (
    tester,
  ) async {
    final fake = FakeAuthRepository();
    addTearDown(fake.changes.close);
    fake.pending = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: Scaffold(body: LogoutButton())),
      ),
    );
    await tester.tap(find.text('Keluar'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    fake.pending!.complete();
    await tester.pumpAndSettle();
    expect(fake.calls, ['logout']);
    fake.pending = null;
    fake.failure = FirebaseAuthException(code: 'network-request-failed');
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Jaringan terputus. Periksa koneksi Anda.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'email form validates, registers customer, displays loading and disabled-account errors',
    (tester) async {
      final fake = FakeAuthRepository();
      addTearDown(fake.changes.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.tap(find.text('Masuk dengan Email'));
      await tester.pumpAndSettle();
      expect(fake.calls, isEmpty);
      await tester.enterText(
        find.byType(TextFormField).first,
        'a@example.test',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.text('Daftar akun pelanggan'));
      await tester.pumpAndSettle();
      fake.pending = Completer<void>();
      await tester.tap(find.text('Daftar'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(fake.calls, ['register:a@example.test']);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      fake.pending!.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sudah punya akun? Masuk'));
      await tester.pumpAndSettle();
      fake.pending = null;
      fake.failure = FirebaseAuthException(code: 'user-disabled');
      await tester.tap(find.text('Masuk dengan Email'));
      await tester.pumpAndSettle();
      expect(
        find.text('Akun dinonaktifkan. Hubungi pengelola bengkel.'),
        findsOneWidget,
      );
      fake.failure = null;
      await tester.tap(find.text('Lupa kata sandi'));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'reset:a@example.test');
      expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
    },
  );

  testWidgets(
    'unverified customer can resend verification and refresh; inactive customer sees account status',
    (tester) async {
      final fake = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          authRepositoryProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fake.changes.close);
      testAuth(container).setSession(
        const AuthSession(
          uid: 'a',
          email: 'a@example.test',
          role: UserRole.customer,
        ),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AccountScreen()),
        ),
      );
      await tester.tap(find.text('Kirim ulang verifikasi'));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'verify');
      await tester.tap(find.text('Periksa ulang status akun'));
      await tester.pumpAndSettle();
      expect(fake.calls.last, 'refresh');
      testAuth(container).setSession(
        const AuthSession(
          uid: 'a',
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
      expect(find.text('Kirim ulang verifikasi'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'customer vehicles UI creates, edits and archives through the Firestore repository',
    (tester) async {
      final database = FakeFirebaseFirestore();
      final fake = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(TestAuthController.new),
          authRepositoryProvider.overrideWithValue(fake),
          firestoreProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fake.changes.close);
      testAuth(container).signIn(UserRole.customer);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BengkelKuApp(),
        ),
      );
      container.read(appRouterProvider).go('/customer/vehicles');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah kendaraan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Honda Brio');
      await tester.enterText(find.byType(TextFormField).last, 'invalid');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Plat harus seperti B 1234 XYZ.'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).last, 'b1234xyz');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('B 1234 XYZ'), findsOneWidget);
      await tester.tap(find.text('Honda Brio'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Honda Brio RS');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Honda Brio RS'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Honda Brio RS'), findsNothing);
      final saved = (await database.collection('vehicles').get()).docs.single;
      expect(saved['active'], false);
      expect(saved['ownerId'], 'customer-demo');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
