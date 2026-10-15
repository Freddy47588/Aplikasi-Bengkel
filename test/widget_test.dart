import 'package:bengkel_kendaraan/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'login page exposes email authentication without role selection',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      expect(find.text('Masuk'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Daftar akun pelanggan'), findsOneWidget);
      expect(find.text('Masuk sebagai Teknisi'), findsNothing);
      expect(find.text('Masuk sebagai Admin'), findsNothing);
    },
  );
}
