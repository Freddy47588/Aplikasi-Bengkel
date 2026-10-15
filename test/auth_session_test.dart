import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession', () {
    test('defaults to unauthenticated state', () {
      const session = AuthSession();

      expect(session.isAuthenticated, isFalse);
      expect(session.role, isNull);
    });

    test('customer role marks the user as authenticated', () {
      const session = AuthSession(
        uid: 'a',
        role: UserRole.customer,
        verified: true,
      );

      expect(session.isAuthenticated, isTrue);
      expect(session.role, UserRole.customer);
    });
  });
}
