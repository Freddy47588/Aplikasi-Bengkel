import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/user_role.dart';
import 'payment_repository.dart';

class WorkshopReport {
  const WorkshopReport(
    this.bookings,
    this.completed,
    this.revenue,
    this.partUnits,
    this.lowStock,
  );
  final int bookings, completed, revenue, partUnits, lowStock;
}

class ReportRepository {
  ReportRepository(this.db, this.role);
  final FirebaseFirestore db;
  final UserRole role;

  // On-demand, date-filtered pages; no live listener or unbounded collection read.
  Future<int> sum(
    Query<Map<String, dynamic>> query,
    int Function(Map<String, dynamic>) value,
  ) async {
    var total = 0;
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      final q = cursor == null ? query : query.startAfterDocument(cursor);
      final s = await q.limit(20).get(const GetOptions(source: Source.server));
      for (final d in s.docs) {
        total += value(d.data());
      }
      if (s.docs.length < 20) return total;
      cursor = s.docs.last;
    }
  }

  Future<WorkshopReport> load(DateTime from, DateTime until) async {
    if (role != UserRole.admin) throw StateError('Laporan hanya admin.');
    if (!until.isAfter(from) || until.difference(from).inDays > 31) {
      throw ArgumentError('Pilih periode 1–31 hari.');
    }
    Query<Map<String, dynamic>> period(String collection, String field) {
      final query = db
          .collection(collection)
          .where(field, isGreaterThanOrEqualTo: from)
          .where(field, isLessThan: until);
      return field == 'completedAt'
          ? query.orderBy(field, descending: true).orderBy(FieldPath.documentId)
          : query.orderBy(field);
    }

    final values = await Future.wait([
      sum(period('bookings', 'createdAt'), (_) => 1),
      sum(
        period(
          'serviceOrders',
          'completedAt',
        ).where('status', isEqualTo: 'completed'),
        (_) => 1,
      ),
      sum(
        period('invoices', 'paidAt').where('status', isEqualTo: 'paid'),
        (d) => d['grandTotal'] as int,
      ),
      sum(
        period('stockMovements', 'createdAt'),
        (d) => d['serviceOrderId'] != null ? -(d['delta'] as int) : 0,
      ),
      sum(
        db
            .collection('spareparts')
            .where('lowStock', isEqualTo: true)
            .where('active', isEqualTo: true)
            .orderBy('sku'),
        (_) => 1,
      ),
    ]);
    return WorkshopReport(
      values[0],
      values[1],
      values[2],
      values[3],
      values[4],
    );
  }
}

final reportRepositoryProvider = Provider((ref) {
  final payments = ref.watch(paymentRepositoryProvider);
  return ReportRepository(payments.db, payments.role);
});
