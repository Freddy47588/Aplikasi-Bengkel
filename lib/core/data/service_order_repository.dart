import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../constants/user_role.dart';
import '../models/service_order.dart';
import 'firebase_providers.dart';

abstract class ServiceOrderRepository {
  Stream<RecordPage<ServiceOrder>> watchOrders({
    DocumentSnapshot<Map<String, dynamic>>? after,
  });
  Stream<ServiceOrder?> watchOrder(String id);
  Stream<RecordPage<Technician>> watchTechnicians({
    DocumentSnapshot<Map<String, dynamic>>? after,
    String search = '',
    bool? active,
    String specialization = '',
  });
  Future<void> saveTechnician(
    String uid,
    String name,
    String specialization,
    bool active,
    bool available,
  );
  Future<void> create(String bookingId);
  Future<void> setLaborPrice(String id, int revision, int rupiah);
  Future<void> assign(String id, String technicianId, int revision);
  Future<void> updateWork(
    String id,
    int revision, {
    ServiceOrderStatus? status,
    required Map<String, bool> checklist,
    required String diagnosis,
    required String actions,
    required String notes,
  });
}

class FirestoreServiceOrderRepository implements ServiceOrderRepository {
  FirestoreServiceOrderRepository(this.db, this.uid, this.role);
  final FirebaseFirestore db;
  final String uid;
  final UserRole role;
  static const pageSize = 20;
  CollectionReference<Map<String, dynamic>> get orders =>
      db.collection('serviceOrders');
  CollectionReference<Map<String, dynamic>> get technicians =>
      db.collection('technicians');
  dynamic get now => FieldValue.serverTimestamp();
  void requireAdmin() {
    if (role != UserRole.admin) throw StateError('Akses admin diperlukan.');
  }

  @override
  Stream<RecordPage<ServiceOrder>> watchOrders({
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) {
    Query<Map<String, dynamic>> q = orders;
    if (role != UserRole.admin) {
      q = q.where(
        role == UserRole.technician ? 'technicianId' : 'customerId',
        isEqualTo: uid,
      );
    }
    q = q.orderBy('createdAt', descending: true).orderBy(FieldPath.documentId);
    if (after != null) q = q.startAfterDocument(after);
    return q
        .limit(pageSize)
        .snapshots()
        .map(
          (s) => RecordPage(
            s.docs.map((d) => ServiceOrder(d.id, d.data())).toList(),
            s.docs.lastOrNull,
            s.docs.length == pageSize,
          ),
        );
  }

  @override
  Stream<ServiceOrder?> watchOrder(String id) => orders
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ServiceOrder(d.id, d.data()!) : null);

  @override
  Stream<RecordPage<Technician>> watchTechnicians({
    DocumentSnapshot<Map<String, dynamic>>? after,
    String search = '',
    bool? active,
    String specialization = '',
  }) {
    requireAdmin();
    Query<Map<String, dynamic>> q = technicians
        .orderBy('name')
        .orderBy(FieldPath.documentId);
    if (active != null) q = q.where('active', isEqualTo: active);
    if (specialization.isNotEmpty) {
      q = q.where('specialization', isEqualTo: specialization);
    }
    if (search.isNotEmpty) {
      q = q
          .where('name', isGreaterThanOrEqualTo: search)
          .where('name', isLessThanOrEqualTo: '$search\uf8ff');
    }
    if (after != null) q = q.startAfterDocument(after);
    return q
        .limit(pageSize)
        .snapshots()
        .map(
          (s) => RecordPage(
            s.docs.map((d) => Technician(d.id, d.data())).toList(),
            s.docs.lastOrNull,
            s.docs.length == pageSize,
          ),
        );
  }

  @override
  Future<void> saveTechnician(
    String target,
    String name,
    String specialization,
    bool active,
    bool available,
  ) async {
    requireAdmin();
    if (target.trim().isEmpty ||
        target.contains('/') ||
        name.trim().isEmpty ||
        name.trim().length > 80 ||
        specialization.trim().isEmpty ||
        specialization.trim().length > 120) {
      throw ArgumentError('UID, nama dan spesialisasi valid diperlukan.');
    }
    final ref = technicians.doc(target);
    await db.runTransaction((tx) async {
      final user = await tx.get(db.collection('users').doc(target));
      final old = await tx.get(ref);
      if (!user.exists ||
          user['role'] != 'technician' ||
          (active && user['active'] != true)) {
        throw StateError(
          'Provision akun teknisi aktif melalui operator tepercaya dahulu.',
        );
      }
      if (!active && old.data()?['currentOrderId'] != null) {
        throw StateError(
          'Selesaikan atau alihkan tugas sebelum menonaktifkan.',
        );
      }
      tx.set(ref, {
        'name': name.trim(),
        'specialization': specialization.trim(),
        'active': active,
        'available': available,
        'currentOrderId': old.data()?['currentOrderId'],
        'createdAt': old.data()?['createdAt'] ?? now,
        'updatedAt': now,
        'updatedBy': uid,
      });
    });
  }

  void event(
    Transaction tx,
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
    String kind,
  ) {
    tx.set(ref.collection('events').doc('${data['revision']}'), {
      'revision': data['revision'],
      'actorId': uid,
      'at': now,
      'kind': kind,
      'status': data['status'],
      'technicianId': data['technicianId'],
    });
  }

  @override
  Future<void> create(String bookingId) async {
    requireAdmin();
    final ref = orders.doc(bookingId);
    await db.runTransaction((tx) async {
      final booking = await tx.get(db.collection('bookings').doc(bookingId));
      final existing = await tx.get(ref);
      if (existing.exists) {
        throw StateError('Service Order booking ini sudah ada.');
      }
      if (!booking.exists || booking['status'] != 'confirmed') {
        throw StateError('Booking harus dikonfirmasi.');
      }
      final b = booking.data()!;
      final data = <String, dynamic>{
        for (final key in [
          'customerId',
          'vehicleId',
          'vehicleName',
          'vehiclePlate',
          'serviceId',
          'serviceName',
          'complaint',
          'scheduledAt',
        ])
          key: b[key],
        'bookingId': bookingId,
        'status': 'queued',
        'technicianId': null,
        'technicianName': null,
        'laborPrice': null,
        'checklist': {for (final key in inspectionKeys) key: false},
        'diagnosis': '',
        'actions': '',
        'notes': '',
        'revision': 0,
        'createdAt': now,
        'createdBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
        'assignedAt': null,
        'assignedBy': null,
        'startedAt': null,
        'completedAt': null,
      };
      tx.set(ref, data);
      event(tx, ref, data, 'created');
    });
  }

  @override
  Future<void> assign(String id, String target, int revision) async {
    requireAdmin();
    final ref = orders.doc(id);
    await db.runTransaction((tx) async {
      final order = await tx.get(ref);
      if (!order.exists) throw StateError('Service Order tidak ditemukan.');
      final d = order.data()!;
      // Same assignment is a no-op, including a retry after an acknowledged commit.
      if (d['technicianId'] == target) return;
      if (d['revision'] != revision ||
          !['queued', 'assigned', 'paused'].contains(d['status'])) {
        throw StateError('Tugas berubah atau sedang dikerjakan. Muat ulang.');
      }
      final tech = await tx.get(technicians.doc(target));
      final user = await tx.get(db.collection('users').doc(target));
      final previous = d['technicianId'] as String?;
      if (previous != null) await tx.get(technicians.doc(previous));
      if (!tech.exists ||
          !Technician(target, tech.data()!).assignable ||
          !user.exists ||
          user['active'] != true ||
          user['role'] != 'technician') {
        throw StateError(
          'Teknisi tidak aktif, tidak tersedia atau sedang bertugas.',
        );
      }
      final changes = <String, dynamic>{
        'technicianId': target,
        'technicianName': tech['name'],
        'status': 'assigned',
        'assignedAt': now,
        'assignedBy': uid,
        'updatedAt': now,
        'updatedBy': uid,
        'revision': revision + 1,
      };
      tx.update(ref, changes);
      tx.update(technicians.doc(target), {'currentOrderId': id});
      if (previous != null) {
        tx.update(technicians.doc(previous), {'currentOrderId': null});
      }
      event(tx, ref, {...d, ...changes}, 'assigned');
    });
  }

  @override
  Future<void> setLaborPrice(String id, int revision, int rupiah) async {
    requireAdmin();
    if (rupiah < 0 || rupiah > 1000000000) {
      throw ArgumentError('Biaya jasa tidak valid.');
    }
    final ref = orders.doc(id);
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Service Order tidak ditemukan.');
      final order = ServiceOrder(id, doc.data()!);
      if (order.status.terminal || order.revision != revision) {
        throw StateError('Tugas berubah atau sudah selesai.');
      }
      final changes = <String, dynamic>{
        'laborPrice': rupiah,
        'revision': revision + 1,
        'updatedAt': now,
        'updatedBy': uid,
      };
      tx.update(ref, changes);
      event(tx, ref, {...order.data, ...changes}, 'pricingUpdated');
    });
  }

  @override
  Future<void> updateWork(
    String id,
    int revision, {
    ServiceOrderStatus? status,
    required Map<String, bool> checklist,
    required String diagnosis,
    required String actions,
    required String notes,
  }) async {
    if (role == UserRole.customer) throw StateError('Tidak diizinkan.');
    if (diagnosis.length > 2000 ||
        actions.length > 2000 ||
        notes.length > 4000 ||
        checklist.length != inspectionKeys.length ||
        !inspectionKeys.every(checklist.containsKey)) {
      throw ArgumentError('Catatan/checklist tidak valid.');
    }
    final ref = orders.doc(id);
    await db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Tugas tidak ditemukan.');
      final order = ServiceOrder(id, doc.data()!);
      final admin = role == UserRole.admin;
      if (order.revision != revision ||
          order.status.terminal ||
          (!admin && order.technicianId != uid)) {
        throw StateError('Tugas berubah atau akses tidak diizinkan.');
      }
      final next = status ?? order.status;
      if (next != order.status &&
          !order.status.canTransitionTo(next, admin: admin)) {
        throw StateError('Transisi tidak diizinkan.');
      }
      if (!admin &&
          ![
            ServiceOrderStatus.inProgress,
            ServiceOrderStatus.paused,
          ].contains(order.status) &&
          next == order.status) {
        throw StateError('Mulai tugas sebelum mengisi catatan.');
      }
      if (next == ServiceOrderStatus.awaitingApproval &&
          (diagnosis.trim().isEmpty ||
              actions.trim().isEmpty ||
              checklist.values.any((v) => !v))) {
        throw StateError('Lengkapi checklist, diagnosis dan tindakan.');
      }
      DocumentSnapshot<Map<String, dynamic>>? completingTech;
      if (order.technicianId != null && next.terminal) {
        completingTech = await tx.get(technicians.doc(order.technicianId));
      }
      if (next == ServiceOrderStatus.completed &&
          order.data['laborPrice'] is! int) {
        throw StateError(
          'Catat biaya jasa (termasuk Rp 0) sebelum menyelesaikan.',
        );
      }
      final changes = <String, dynamic>{
        'status': next.name,
        'updatedAt': now,
        'updatedBy': uid,
        'revision': revision + 1,
        if (!admin) ...{
          'checklist': checklist,
          'diagnosis': diagnosis.trim(),
          'actions': actions.trim(),
          'notes': notes.trim(),
        },
        if (next == ServiceOrderStatus.inProgress &&
            order.data['startedAt'] == null)
          'startedAt': now,
        if (next == ServiceOrderStatus.completed) ...{
          'completedAt': now,
          'technicianName':
              order.data['technicianName'] ?? completingTech?.data()?['name'],
        },
      };
      if (admin && next == order.status) {
        throw StateError('Pilih perubahan status.');
      }
      tx.update(ref, changes);
      if (order.technicianId != null && next.terminal) {
        tx.update(technicians.doc(order.technicianId), {
          'currentOrderId': null,
        });
      }
      event(tx, ref, {
        ...order.data,
        ...changes,
      }, next == order.status ? 'workUpdated' : 'statusChanged');
    });
  }
}

final serviceOrderRepositoryProvider = Provider<ServiceOrderRepository>((ref) {
  final s = ref.watch(authSessionProvider);
  return FirestoreServiceOrderRepository(
    ref.watch(firestoreProvider),
    s.userId,
    s.role ?? UserRole.customer,
  );
});
final serviceOrderProvider = StreamProvider.autoDispose
    .family<ServiceOrder?, String>((ref, id) {
      if (!ref.watch(authSessionProvider).isAuthenticated) {
        return Stream.value(null);
      }
      return ref.watch(serviceOrderRepositoryProvider).watchOrder(id);
    });
