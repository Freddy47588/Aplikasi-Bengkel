import 'package:bengkel_kendaraan/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login page shows demo role buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Mode Demo'), findsOneWidget);
    expect(find.text('Masuk sebagai Pelanggan'), findsOneWidget);
    expect(find.text('Masuk sebagai Teknisi'), findsOneWidget);
    expect(find.text('Masuk sebagai Admin'), findsOneWidget);
  });
}
