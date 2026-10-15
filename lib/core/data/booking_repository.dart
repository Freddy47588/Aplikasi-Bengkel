import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/user_role.dart';
import '../models/booking.dart';

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

class InMemoryBookingRepository implements BookingRepository {
  InMemoryBookingRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final _changes = StreamController<List<Booking>>.broadcast();
  final List<Booking> _items = [];
  int _sequence = 0;
  List<Booking> get snapshot => List.unmodifiable(_items);
  @override
  Stream<List<Booking>> watch() {
    // Subscribe before delivering the initial snapshot to avoid losing a mutation.
    return Stream<List<Booking>>.multi((sink) {
      final subscription = _changes.stream.listen(
        sink.add,
        onError: sink.addError,
        onDone: sink.close,
      );
      sink.add(snapshot);
      sink.onCancel = subscription.cancel;
    });
  }

  @override
  Future<Booking> submit(String customerId, BookingDraft draft) async {
    final error = draft.validate(_clock());
    if (error != null) throw ArgumentError(error);
    if (customerId.trim().isEmpty) {
      throw ArgumentError('Sesi pelanggan tidak valid.');
    }
    if (_items.any(
      (b) =>
          b.status.isActive &&
          b.draft.vehicleId == draft.vehicleId &&
          b.draft.scheduledAt == draft.scheduledAt,
    )) {
      throw StateError('Kendaraan sudah memiliki booking pada jadwal ini.');
    }
    final booking = Booking(
      id: 'BKG-${++_sequence}',
      customerId: customerId,
      draft: draft,
    );
    _items.add(booking);
    _changes.add(snapshot);
    return booking;
  }

  @override
  Future<void> updateStatus(
    String id,
    BookingStatus status, {
    required UserRole actor,
    required String actorId,
  }) async {
    final index = _items.indexWhere((b) => b.id == id);
    if (index < 0) throw StateError('Booking tidak ditemukan.');
    final booking = _items[index];
    final adminAction =
        actor == UserRole.admin &&
        booking.status == BookingStatus.pending &&
        (status == BookingStatus.confirmed || status == BookingStatus.rejected);
    final customerAction =
        actor == UserRole.customer &&
        booking.customerId == actorId &&
        booking.status.isActive &&
        status == BookingStatus.cancelled;
    if (!adminAction && !customerAction) {
      throw StateError('Perubahan status tidak diizinkan.');
    }
    _items[index] = booking.withStatus(status);
    _changes.add(snapshot);
  }

  @override
  Future<void> dispose() => _changes.close();
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final repository = InMemoryBookingRepository();
  ref.onDispose(repository.dispose);
  return repository;
});
final bookingsProvider = StreamProvider<List<Booking>>(
  (ref) => ref.watch(bookingRepositoryProvider).watch(),
);
