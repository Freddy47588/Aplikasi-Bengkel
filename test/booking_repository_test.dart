import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 14, 8);
  BookingDraft draft({
    String vehicle = 'brio',
    String service = 'Ganti Oli',
    DateTime? date,
    String complaint = 'Mesin berbunyi',
  }) => BookingDraft(
    vehicleId: vehicle,
    service: service,
    scheduledAt: date ?? DateTime(2026, 10, 15, 9),
    complaint: complaint,
  );
  for (final role in UserRole.values) {
    test('login/logout ${role.name} and role guards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final auth = container.read(authSessionProvider.notifier);
      expect(
        sessionRedirect(
          container.read(authSessionProvider),
          '/${role.name}/home',
        ),
        '/login',
      );
      auth.signIn(role);
      final session = container.read(authSessionProvider);
      expect(session.role, role);
      expect(sessionRedirect(session, '/login'), '/${role.name}/home');
      expect(sessionRedirect(session, '/${role.name}'), '/${role.name}/home');
      expect(sessionRedirect(session, '/${role.name}/home'), isNull);
      for (final other in UserRole.values.where((other) => other != role)) {
        expect(
          sessionRedirect(session, '/${other.name}/home'),
          '/${role.name}/home',
        );
      }
      auth.signOut();
      expect(container.read(authSessionProvider).isAuthenticated, isFalse);
    });
  }
  test(
    'booking validation rejects invalid fields and expired/outside hours',
    () {
      expect(draft().validate(now), isNull);
      for (final invalid in [
        draft(vehicle: ''),
        draft(service: ''),
        draft(complaint: 'a'),
        draft(complaint: 'a' * 501),
        draft(date: now),
        draft(date: now.add(const Duration(days: 91))),
        draft(date: DateTime(2026, 10, 15, 12)),
        draft(date: DateTime(2026, 10, 15, 9, 30)),
      ]) {
        expect(invalid.validate(now), isNotNull);
      }
    },
  );
  test(
    'submission, independent subscribers, admin update and cancellation synchronize',
    () async {
      final repository = InMemoryBookingRepository(clock: () => now);
      addTearDown(repository.dispose);
      final customer = <List<Booking>>[];
      final admin = <List<Booking>>[];
      final sub1 = repository.watch().listen(customer.add);
      final sub2 = repository.watch().listen(admin.add);
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);
      final booking = await repository.submit('customer-demo', draft());
      await Future<void>.delayed(Duration.zero);
      expect(customer.last.single.id, booking.id);
      expect(admin.last.single.status, BookingStatus.pending);
      await repository.updateStatus(
        booking.id,
        BookingStatus.confirmed,
        actor: UserRole.admin,
        actorId: 'admin-demo',
      );
      await Future<void>.delayed(Duration.zero);
      expect(customer.last.single.status, BookingStatus.confirmed);
      expect(admin.last.single.status, BookingStatus.confirmed);
      await repository.updateStatus(
        booking.id,
        BookingStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'customer-demo',
      );
      await Future<void>.delayed(Duration.zero);
      expect(admin.last.single.status, BookingStatus.cancelled);
    },
  );
  test('reject, duplicate, ownership and terminal transition rules', () async {
    final repository = InMemoryBookingRepository(clock: () => now);
    addTearDown(repository.dispose);
    await expectLater(
      repository.submit('customer-demo', draft(complaint: '')),
      throwsArgumentError,
    );
    final booking = await repository.submit('customer-demo', draft());
    await expectLater(
      repository.submit('customer-demo', draft()),
      throwsStateError,
    );
    await expectLater(
      repository.updateStatus(
        booking.id,
        BookingStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'another-customer',
      ),
      throwsStateError,
    );
    await expectLater(
      repository.updateStatus(
        booking.id,
        BookingStatus.confirmed,
        actor: UserRole.technician,
        actorId: 'tech',
      ),
      throwsStateError,
    );
    await repository.updateStatus(
      booking.id,
      BookingStatus.rejected,
      actor: UserRole.admin,
      actorId: 'admin-demo',
    );
    expect(repository.snapshot.single.status, BookingStatus.rejected);
    await expectLater(
      repository.updateStatus(
        booking.id,
        BookingStatus.confirmed,
        actor: UserRole.admin,
        actorId: 'admin-demo',
      ),
      throwsStateError,
    );
    await expectLater(
      repository.updateStatus(
        'missing',
        BookingStatus.confirmed,
        actor: UserRole.admin,
        actorId: 'admin-demo',
      ),
      throwsStateError,
    );
  });
}
