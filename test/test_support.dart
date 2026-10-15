import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bengkel_kendaraan/app/router/app_router.dart';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/data/booking_repository.dart';
import 'package:bengkel_kendaraan/core/data/service_repository.dart';
import 'package:bengkel_kendaraan/core/data/vehicle_repository.dart';

const demoVehicles = [
  Vehicle('brio', 'Honda Brio RS', 'B 1234 XYZ'),
  Vehicle('avanza', 'Toyota Avanza', 'N 1234 AB'),
];
const serviceTypes = [
  'Service Berkala',
  'Ganti Oli',
  'Tune Up',
  'Pemeriksaan Rem',
];

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

class TestAuthController extends AuthSessionController {
  @override
  AuthSession build() => const AuthSession();
  void signIn(UserRole role) {
    state = AuthSession(uid: '${role.name}-demo', role: role, verified: true);
  }

  void setSession(AuthSession session) {
    state = session;
  }

  @override
  Future<void> signOut() async {
    state = const AuthSession();
  }
}

TestAuthController testAuth(ProviderContainer container) =>
    container.read(authSessionProvider.notifier) as TestAuthController;
ProviderContainer testContainer({Stream<List<Booking>>? bookings}) =>
    ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(TestAuthController.new),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        bookingRepositoryProvider.overrideWith((ref) {
          final repo = InMemoryBookingRepository();
          ref.onDispose(repo.dispose);
          return repo;
        }),
        vehiclesProvider.overrideWith((ref) => Stream.value(demoVehicles)),
        servicesProvider.overrideWith(
          (ref) => Stream.value(
            serviceTypes.map((s) => WorkshopService(s, s)).toList(),
          ),
        ),
        if (bookings != null) bookingsProvider.overrideWith((ref) => bookings),
      ],
    );

class FakeAuthRepository implements AuthRepository {
  final changes = StreamController<AuthSession>.broadcast(sync: true);
  final calls = <String>[];
  Object? failure;
  Completer<void>? pending;
  @override
  Stream<AuthSession> watch() => changes.stream;
  Future<void> operation(String call) async {
    calls.add(call);
    if (failure != null) throw failure!;
    await pending?.future;
  }

  @override
  Future<void> login(String email, String password) =>
      operation('login:$email');
  @override
  Future<void> register(String email, String password) =>
      operation('register:$email');
  @override
  Future<void> resetPassword(String email) => operation('reset:$email');
  @override
  Future<void> sendVerification() => operation('verify');
  @override
  Future<void> completeProfile() => operation('profile');
  @override
  Future<void> refresh() => operation('refresh');
  @override
  Future<void> signOut() async {
    await operation('logout');
    changes.add(const AuthSession());
  }
}
