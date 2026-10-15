import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/user_role.dart';
import '../models/booking.dart';
import '../../features/auth/data/auth_repository.dart';
import 'firebase_providers.dart';
import 'firestore_booking_repository.dart';

abstract class BookingRepository {
  Stream<List<Booking>> watch();
  Future<Booking> submit(String customerId, BookingDraft draft);
  Future<void> updateStatus(
    String id,
    BookingStatus status, {
    required UserRole actor,
    required String actorId,
  });
  Future<void> dispose();
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final session = ref.watch(authSessionProvider);
  if (!session.isAuthenticated) return _NoSessionBookingRepository();
  return FirestoreBookingRepository(
    ref.watch(firestoreProvider),
    uid: session.userId,
    role: session.role!,
  );
});

class _NoSessionBookingRepository implements BookingRepository {
  @override
  Stream<List<Booking>> watch() => Stream.value([]);
  @override
  Future<Booking> submit(String customerId, BookingDraft draft) async =>
      throw StateError('Sesi diperlukan.');
  @override
  Future<void> updateStatus(
    String id,
    BookingStatus status, {
    required UserRole actor,
    required String actorId,
  }) async => throw StateError('Sesi diperlukan.');
  @override
  Future<void> dispose() async {}
}

final bookingsProvider = StreamProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).watch(),
);
