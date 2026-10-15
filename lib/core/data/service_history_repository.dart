import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../constants/user_role.dart';
import '../models/service_order.dart';
import '../models/service_history.dart';
import 'firebase_providers.dart';

class FirestoreServiceHistoryRepository {
  FirestoreServiceHistoryRepository(this.db, this.uid, this.role);
  final FirebaseFirestore db;
  final String uid;
  final UserRole role;
  static const pageSize = 20;
  Stream<RecordPage<ServiceOrder>> watch(HistoryFilter filter) {
    if (filter.from != null &&
        filter.until != null &&
        !filter.until!.isAfter(filter.from!)) {
      throw ArgumentError('Periode tidak valid.');
    }
    Query<Map<String, dynamic>> q = db
        .collection('serviceOrders')
        .where('status', isEqualTo: 'completed');
    if (role != UserRole.admin) {
      q = q.where(
        role == UserRole.customer ? 'customerId' : 'technicianId',
        isEqualTo: uid,
      );
    }
    if (filter.vehicleId.isNotEmpty) {
      q = q.where('vehicleId', isEqualTo: filter.vehicleId);
    }
    if (filter.serviceId.isNotEmpty) {
      q = q.where('serviceId', isEqualTo: filter.serviceId);
    }
    if (filter.from != null) {
      q = q.where(
        'completedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter.from!),
      );
    }
    if (filter.until != null) {
      q = q.where('completedAt', isLessThan: Timestamp.fromDate(filter.until!));
    }
    q = q
        .orderBy('completedAt', descending: true)
        .orderBy(FieldPath.documentId);
    if (filter.cursor != null) q = q.startAfterDocument(filter.cursor!);
    return q
        .limit(pageSize)
        .snapshots(includeMetadataChanges: true)
        .map(
          (s) => RecordPage(
            s.docs.map((d) => ServiceOrder(d.id, d.data())).toList(),
            s.docs.lastOrNull,
            s.docs.length == pageSize,
            fromCache: s.metadata.isFromCache,
          ),
        );
  }

  /// Immutable sales lines only. Each request is bounded by rules (20).
  /// Completed SOs cannot receive usages or reversals, so pages are stable.
  Future<HistoryParts> parts(String orderId) async {
    final order = await db.collection('serviceOrders').doc(orderId).get();
    if (!order.exists || order.data()?['status'] != 'completed') {
      throw StateError('Riwayat hanya untuk Service Order selesai.');
    }
    if (role != UserRole.admin &&
        order.data()?[role == UserRole.customer
                ? 'customerId'
                : 'technicianId'] !=
            uid) {
      throw StateError('Riwayat tidak diizinkan.');
    }
    final lines = <Map<String, dynamic>>[];
    var cached = order.metadata.isFromCache;
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      Query<Map<String, dynamic>> q = db
          .collection('serviceOrders')
          .doc(orderId)
          .collection('partUsages')
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId);
      if (cursor != null) q = q.startAfterDocument(cursor);
      final page = await q.limit(pageSize).get();
      cached = cached || page.metadata.isFromCache;
      lines.addAll(page.docs.map((d) => {'id': d.id, ...d.data()}));
      if (page.docs.length < pageSize) break;
      cursor = page.docs.last;
    }
    return HistoryParts(lines, fromCache: cached);
  }
}

final serviceHistoryRepositoryProvider = Provider((ref) {
  final session = ref.watch(authSessionProvider);
  return FirestoreServiceHistoryRepository(
    ref.watch(firestoreProvider),
    session.userId,
    session.role ?? UserRole.customer,
  );
});
final historyPageProvider = StreamProvider.autoDispose
    .family<RecordPage<ServiceOrder>, HistoryFilter>((ref, filter) {
      if (!ref.watch(authSessionProvider).isAuthenticated) {
        return Stream.value(const RecordPage([], null, false));
      }
      return ref.watch(serviceHistoryRepositoryProvider).watch(filter);
    });
final historyPartsProvider = FutureProvider.autoDispose
    .family<HistoryParts, String>((ref, id) {
      if (!ref.watch(authSessionProvider).isAuthenticated) {
        throw StateError('Sesi diperlukan.');
      }
      return ref.watch(serviceHistoryRepositoryProvider).parts(id);
    });
