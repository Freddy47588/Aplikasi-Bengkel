import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/user_role.dart';
import '../models/booking.dart';
import 'booking_repository.dart';

bool canChangeBooking(
  BookingStatus before,
  BookingStatus after,
  UserRole actor,
  bool owner,
) =>
    (actor == UserRole.admin &&
        before == BookingStatus.pending &&
        (after == BookingStatus.confirmed ||
            after == BookingStatus.rejected)) ||
    (actor == UserRole.customer &&
        owner &&
        before.isActive &&
        after == BookingStatus.cancelled);

class FirestoreBookingRepository implements BookingRepository {
  FirestoreBookingRepository(this.db, {required this.uid, required this.role});
  final FirebaseFirestore db;
  final String uid;
  final UserRole role;
  @override
  Stream<List<Booking>> watch() {
    if (role != UserRole.customer && role != UserRole.admin) {
      return Stream.value([]);
    }
    Query<Map<String, dynamic>> query = db.collection('bookings');
    if (role == UserRole.customer) {
      query = query.where('customerId', isEqualTo: uid);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map((d) => decode(d.id, d.data())).toList());
  }

  static Booking decode(String id, Map<String, dynamic> d) => Booking(
    id: id,
    customerId: d['customerId'] as String,
    status: BookingStatus.values.byName(d['status'] as String),
    draft: BookingDraft(
      vehicleId: d['vehicleId'] as String,
      serviceId: d['serviceId'] as String,
      service: d['serviceName'] as String,
      vehicleName: d['vehicleName'] as String,
      vehiclePlate: d['vehiclePlate'] as String,
      scheduledAt: (d['scheduledAt'] as Timestamp).toDate().toUtc(),
      complaint: d['complaint'] as String,
    ),
  );
  @override
  Future<Booking> submit(String customerId, BookingDraft draft) async {
    if (role != UserRole.customer || customerId != uid) {
      throw StateError('Sesi pelanggan tidak valid.');
    }
    final error = draft.validate(DateTime.now());
    if (error != null || draft.serviceId == null) {
      throw ArgumentError(error ?? 'Pilih layanan.');
    }
    final booking = db.collection('bookings').doc();
    final at = draft.scheduledAt.toUtc();
    final slotId = at.millisecondsSinceEpoch.toString();
    final slot = db.collection('bookingSlots').doc(slotId);
    return db.runTransaction((tx) async {
      // All reads precede writes; retry on contention, never emit side effects here.
      final lock = await tx.get(slot);
      final vehicle = await tx.get(
        db.collection('vehicles').doc(draft.vehicleId),
      );
      final service = await tx.get(
        db.collection('services').doc(draft.serviceId),
      );
      if (lock.exists && lock['active'] == true) {
        throw StateError('Slot sudah terisi. Pilih jadwal lain.');
      }
      if (!vehicle.exists ||
          vehicle['ownerId'] != uid ||
          vehicle['active'] != true) {
        throw StateError('Kendaraan tidak tersedia untuk akun ini.');
      }
      if (!service.exists || service['active'] != true) {
        throw StateError('Layanan tidak tersedia.');
      }
      final data = <String, dynamic>{
        'customerId': uid,
        'vehicleId': vehicle.id,
        'vehicleName': vehicle['name'],
        'vehiclePlate': vehicle['plate'],
        'serviceId': service.id,
        'serviceName': service['name'],
        'scheduledAt': Timestamp.fromDate(at),
        'complaint': draft.complaint.trim(),
        'status': 'pending',
        'slotId': slotId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      tx.set(booking, data);
      tx.set(slot, {
        'bookingId': booking.id,
        'scheduledAt': Timestamp.fromDate(at),
        'active': true,
      });
      return decode(booking.id, data);
    });
  }

  @override
  Future<void> updateStatus(
    String id,
    BookingStatus status, {
    required UserRole actor,
    required String actorId,
  }) async {
    if (actor != role || actorId != uid) throw StateError('Sesi tidak sesuai.');
    final booking = db.collection('bookings').doc(id);
    await db.runTransaction((tx) async {
      final doc = await tx.get(booking);
      if (!doc.exists) throw StateError('Booking tidak ditemukan.');
      if (status == BookingStatus.cancelled) {
        final order = await tx.get(db.collection('serviceOrders').doc(id));
        if (order.exists) {
          throw StateError(
            'Servis sudah diproses. Hubungi admin untuk pembatalan.',
          );
        }
      }
      final before = BookingStatus.values.byName(doc['status'] as String);
      if (!canChangeBooking(before, status, role, doc['customerId'] == uid)) {
        throw StateError('Perubahan status tidak diizinkan.');
      }
      tx.update(booking, {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!status.isActive) {
        tx.update(db.collection('bookingSlots').doc(doc['slotId'] as String), {
          'active': false,
        });
      }
    });
  }

  @override
  Future<void> dispose() async {}
}
