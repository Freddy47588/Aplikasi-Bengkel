import 'dart:async';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/firestore_booking_repository.dart';
import 'package:bengkel_kendaraan/core/data/vehicle_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCredential extends Mock implements UserCredential {}

void main() {
  late MockAuth auth;
  late MockUser user;
  late FakeFirebaseFirestore db;
  late FirebaseAuthRepository repo;
  setUp(() {
    auth = MockAuth();
    user = MockUser();
    db = FakeFirebaseFirestore();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('a');
    when(() => user.email).thenReturn('a@example.test');
    when(() => user.emailVerified).thenReturn(false);
    repo = FirebaseAuthRepository(auth, db);
  });
  test(
    'register creates only a customer and sends verification; trusted role is never overwritten on login',
    () async {
      final credential = MockCredential();
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'a@example.test',
          password: 'password123',
        ),
      ).thenAnswer((_) async => credential);
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'a@example.test',
          password: 'password123',
        ),
      ).thenAnswer((_) async => credential);
      when(() => user.sendEmailVerification()).thenAnswer((_) async {});
      await repo.register(' a@example.test ', 'password123');
      expect((await db.doc('users/a').get())['role'], 'customer');
      verify(() => user.sendEmailVerification()).called(1);
      await db.doc('users/a').update({'role': 'admin', 'active': false});
      await repo.login('a@example.test', 'password123');
      final profile = (await db.doc('users/a').get()).data()!;
      expect(profile['role'], 'admin');
      expect(profile['active'], false);
    },
  );
  test(
    'failed verification leaves retriable customer profile and refresh forces token renewal',
    () async {
      final credential = MockCredential();
      when(
        () => auth.createUserWithEmailAndPassword(
          email: 'a@example.test',
          password: 'password123',
        ),
      ).thenAnswer((_) async => credential);
      when(
        () => user.sendEmailVerification(),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      await expectLater(
        repo.register('a@example.test', 'password123'),
        throwsA(isA<FirebaseAuthException>()),
      );
      await repo.completeProfile();
      expect((await db.doc('users/a').get())['role'], 'customer');
      when(() => user.reload()).thenAnswer((_) async {});
      when(() => user.getIdToken(true)).thenAnswer((_) async => 'refreshed');
      await repo.refresh();
      verify(() => user.getIdToken(true)).called(1);
    },
  );
  test('disabled Firebase Auth account is signed out on refresh', () async {
    when(
      () => user.reload(),
    ).thenThrow(FirebaseAuthException(code: 'user-disabled'));
    when(() => auth.signOut()).thenAnswer((_) async {});
    await expectLater(repo.refresh(), throwsA(isA<FirebaseAuthException>()));
    verify(() => auth.signOut()).called(1);
  });
  test(
    'profile stream switches accounts without leaking prior user updates; deactivation is live',
    () async {
      final changes = StreamController<User?>();
      when(() => auth.idTokenChanges()).thenAnswer((_) => changes.stream);
      await db.doc('users/a').set({'role': 'customer', 'active': true});
      final values = <AuthSession>[];
      final subscription = repo.watch().listen(values.add);
      changes.add(user);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last.verified, false);
      when(() => user.emailVerified).thenReturn(true);
      changes.add(user);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last.isAuthenticated, true);
      await db.doc('users/a').update({'active': false});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last.isAuthenticated, false);
      changes.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await db.doc('users/a').update({'active': true});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(values.last.uid, isNull);
      await subscription.cancel();
      await changes.close();
    },
  );
  test(
    'vehicle create/update/archive persists and owner cannot be reassigned through repository',
    () async {
      final vehicles = FirestoreVehicleRepository(db);
      await vehicles.save('a', 'Honda', 'b1234xyz');
      final first = (await vehicles.watch('a').first).single;
      expect(first.plate, 'B 1234 XYZ');
      await expectLater(
        vehicles.save('b', 'Stolen', 'B 9 A', id: first.id),
        throwsStateError,
      );
      await expectLater(vehicles.delete('b', first.id), throwsStateError);
      await vehicles.save('a', 'Toyota', 'AB 22 CD', id: first.id);
      expect((await vehicles.watch('a').first).single.name, 'Toyota');
      final restarted = FirestoreVehicleRepository(db);
      expect((await restarted.watch('a').first).single.id, first.id);
      await restarted.delete('a', first.id);
      expect(await restarted.watch('a').first, isEmpty);
      await expectLater(
        restarted.save('a', 'Again', 'B 9 A', id: first.id),
        throwsStateError,
      );
      for (final invalid in [
        '',
        '1234',
        'ABC 1234',
        'B 12345 XYZ',
        'B 2 ABCD',
      ]) {
        expect(() => normalizePlate(invalid), throwsArgumentError);
      }
    },
  );
  test(
    'Firestore booking uses actual catalog snapshots and UTC, releases lock and preserves history after vehicle deletion',
    () async {
      await FirestoreVehicleRepository(db).save('a', 'Honda', 'B 1234 XYZ');
      final v = (await db.collection('vehicles').get()).docs.single;
      await db.doc('services/oil').set({'name': 'Ganti Oli', 'active': true});
      final client = FirestoreBookingRepository(
        db,
        uid: 'a',
        role: UserRole.customer,
      );
      final day = DateTime.now().toUtc().add(const Duration(days: 2));
      final at = DateTime.utc(day.year, day.month, day.day, 2);
      final draft = BookingDraft(
        vehicleId: v.id,
        service: 'Ganti Oli',
        serviceId: 'oil',
        scheduledAt: at,
        complaint: 'Mesin berbunyi',
      );
      final created = await client.submit('a', draft);
      expect(created.vehicle.name, 'Honda');
      expect(created.draft.scheduledAt, at);
      await expectLater(client.submit('a', draft), throwsStateError);
      await expectLater(client.submit('b', draft), throwsStateError);
      await FirestoreVehicleRepository(db).delete('a', v.id);
      final restored = (await FirestoreBookingRepository(
        db,
        uid: 'a',
        role: UserRole.customer,
      ).watch().first).single;
      expect(restored.vehicle.plate, 'B 1234 XYZ');
      final admin = FirestoreBookingRepository(
        db,
        uid: 'admin',
        role: UserRole.admin,
      );
      await admin.updateStatus(
        created.id,
        BookingStatus.confirmed,
        actor: UserRole.admin,
        actorId: 'admin',
      );
      await expectLater(
        admin.updateStatus(
          created.id,
          BookingStatus.rejected,
          actor: UserRole.admin,
          actorId: 'admin',
        ),
        throwsStateError,
      );
      await client.updateStatus(
        created.id,
        BookingStatus.cancelled,
        actor: UserRole.customer,
        actorId: 'a',
      );
      expect(
        (await db
            .doc('bookingSlots/${at.millisecondsSinceEpoch}')
            .get())['active'],
        false,
      );
      expect(
        (await db.doc('bookings/${created.id}').get())['status'],
        'cancelled',
      );
      final data = (await db.doc('bookings/${created.id}').get()).data()!;
      expect(data['createdAt'], isA<Timestamp>());
    },
  );
  test(
    'redirect gates loading, missing profile, unverified and inactive accounts',
    () {
      for (final s in [
        const AuthSession(loading: true),
        const AuthSession(uid: 'a'),
        const AuthSession(uid: 'a', role: UserRole.customer),
        const AuthSession(
          uid: 'a',
          role: UserRole.customer,
          verified: true,
          active: false,
        ),
      ]) {
        expect(sessionRedirect(s, '/customer/home'), '/account');
        expect(sessionRedirect(s, '/account'), isNull);
      }
      expect(sessionRedirect(const AuthSession(), '/admin/home'), '/login');
      expect(
        sessionRedirect(
          const AuthSession(uid: 'a', role: UserRole.customer, verified: true),
          '/admin/home',
        ),
        '/customer/home',
      );
    },
  );
}
