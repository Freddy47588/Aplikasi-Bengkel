import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../constants/user_role.dart';
import '../models/invoice.dart';
import '../models/service_order.dart';
import 'firebase_providers.dart';
import 'service_history_repository.dart';

class PaymentRepository {
  PaymentRepository(this.db, this.uid, this.role);
  final FirebaseFirestore db;
  final String uid;
  final UserRole role;
  CollectionReference<Map<String, dynamic>> get invoices =>
      db.collection('invoices');
  FieldValue get now => FieldValue.serverTimestamp();
  void adminOnly() {
    if (role != UserRole.admin) {
      throw StateError('Akses admin/kasir diperlukan.');
    }
  }

  String newKey() => invoices.doc().id;
  void reasonValid(String reason) {
    if (reason.trim().isEmpty || reason.length > 500) {
      throw ArgumentError('Catatan/alasan wajib, maksimal 500 karakter.');
    }
  }

  Future<void> create(
    String orderId, {
    int discount = 0,
    int fee = 0,
    required String reason,
  }) async {
    adminOnly();
    reasonValid(reason);
    // Completed orders and their usage ledger are immutable under rules.
    final parts = await FirestoreServiceHistoryRepository(
      db,
      uid,
      role,
    ).parts(orderId);
    if (parts.fromCache) {
      throw StateError('Sambungkan jaringan untuk menerbitkan invoice.');
    }
    if (parts.lines.length > 100) {
      throw StateError('Maksimal 100 baris part per invoice.');
    }
    final ref = invoices.doc(orderId);
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      final order = await tx.get(db.collection('serviceOrders').doc(orderId));
      if (old.exists) {
        return; // deterministic identity: one invoice per SO forever
      }
      final so = order.data();
      if (so == null ||
          so['status'] != 'completed' ||
          so['laborPrice'] is! int) {
        throw StateError('SO harus selesai dan biaya jasa disahkan.');
      }
      final totals = InvoiceTotals(
        so['laborPrice'] as int,
        parts.lines,
        discount,
        fee,
      );
      final data = <String, dynamic>{
        'invoiceNo': 'INV~$orderId',
        'serviceOrderId': orderId,
        'customerId': so['customerId'],
        'serviceName': so['serviceName'],
        'vehiclePlate': so['vehiclePlate'],
        'laborPrice': so['laborPrice'],
        'parts': parts.lines,
        'partSubtotal': totals.partSubtotal,
        'subtotal': totals.subtotal,
        'discount': discount,
        'fee': fee,
        'grandTotal': totals.grandTotal,
        'paidAmount': 0,
        'change': 0,
        'due': totals.grandTotal,
        'method': 'none',
        'status': 'unpaid',
        'recordedBy': uid,
        'paidAt': null,
        'createdAt': now,
        'updatedAt': now,
        'notes': reason.trim(),
        'revision': 0,
        'lastKey': 'issued',
      };
      tx.set(ref, data);
      tx.set(ref.collection('payments').doc('issued'), {
        'key': 'issued',
        'revision': 0,
        'kind': 'issued',
        'amount': 0,
        'applied': 0,
        'change': 0,
        'method': 'none',
        'notes': reason.trim(),
        'recordedBy': uid,
        'paidAt': now,
      });
    });
  }

  Future<void> record(
    String id,
    String key,
    int revision, {
    required String kind,
    int amount = 0,
    String method = 'none',
    required String reason,
  }) async {
    adminOnly();
    reasonValid(reason);
    if (!RegExp(r'^[A-Za-z0-9_-]{10,100}$').hasMatch(key) ||
        !['payment', 'void', 'refund'].contains(kind)) {
      throw ArgumentError('Kunci/aksi tidak valid.');
    }
    final ref = invoices.doc(id);
    final event = ref.collection('payments').doc(key);
    bool matches(Map<String, dynamic> p) =>
        p['kind'] == kind &&
        p['amount'] == amount &&
        p['method'] == method &&
        p['notes'] == reason.trim() &&
        p['recordedBy'] == uid;
    try {
      await db.runTransaction((tx) async {
        final previous = await tx.get(event);
        final snap = await tx.get(ref);
        if (previous.exists) {
          final p = previous.data()!;
          if (!matches(p)) {
            throw StateError('Kunci sudah digunakan untuk operasi berbeda.');
          }
          return;
        }
        final d = snap.data();
        if (d == null || d['revision'] != revision) {
          throw StateError('Invoice berubah. Muat ulang.');
        }
        final status = d['status'];
        final paid = d['paidAmount'] as int;
        final due = d['due'] as int;
        var applied = 0;
        var change = 0;
        late String next;
        if (kind == 'payment') {
          if (!['unpaid', 'partial'].contains(status) ||
              amount <= 0 ||
              amount > maxInvoiceRupiah ||
              !['cash', 'transfer'].contains(method) ||
              (method == 'transfer' && amount > due)) {
            throw StateError(
              'Pembayaran tidak valid; transfer harus diverifikasi manual.',
            );
          }
          applied = amount > due ? due : amount;
          change = amount - applied;
          next = applied == due ? 'paid' : 'partial';
        } else if (kind == 'void') {
          if (status != 'unpaid' || amount != 0 || method != 'none') {
            throw StateError('Void hanya untuk invoice belum dibayar.');
          }
          next = 'void';
        } else {
          if (!['partial', 'paid'].contains(status) ||
              amount != paid ||
              !['cash', 'transfer'].contains(method)) {
            throw StateError(
              'Refund manual harus penuh sebesar saldo pembayaran.',
            );
          }
          applied = -paid;
          next = 'refunded';
        }
        tx.update(ref, {
          'paidAmount': paid + applied,
          'change': (d['change'] as int) + change,
          'due': kind == 'payment' ? due - applied : 0,
          'status': next,
          'method': method,
          'recordedBy': uid,
          'updatedAt': now,
          'paidAt': next == 'paid' ? now : d['paidAt'],
          'notes': reason.trim(),
          'revision': revision + 1,
          'lastKey': key,
        });
        tx.set(event, {
          'key': key,
          'revision': revision + 1,
          'kind': kind,
          'amount': amount,
          'applied': applied,
          'change': change,
          'method': method,
          'notes': reason.trim(),
          'recordedBy': uid,
          'paidAt': now,
        });
      });
    } on FirebaseException catch (error) {
      // Concurrent commits can fail authorization before the SDK retries.
      // Only a server-confirmed identical immutable event proves success.
      if ([
        'permission-denied',
        'aborted',
        'unavailable',
        'deadline-exceeded',
      ].contains(error.code)) {
        final committed = await event.get(
          const GetOptions(source: Source.server),
        );
        if (committed.exists && matches(committed.data()!)) return;
      }
      rethrow;
    }
  }

  Future<RecordPage<Invoice>> list(InvoiceFilter f) async {
    if (!f.until.isAfter(f.from)) throw ArgumentError('Periode tidak valid.');
    Query<Map<String, dynamic>> q = invoices;
    if (role != UserRole.admin) q = q.where('customerId', isEqualTo: uid);
    q = q
        .where('createdAt', isGreaterThanOrEqualTo: f.from)
        .where('createdAt', isLessThan: f.until)
        .orderBy('createdAt', descending: true);
    if (f.cursor != null) q = q.startAfterDocument(f.cursor!);
    final s = await q.limit(20).get();
    return RecordPage(
      s.docs.map((d) => Invoice(d.id, d.data())).toList(),
      s.docs.lastOrNull,
      s.docs.length == 20,
      fromCache: s.metadata.isFromCache,
    );
  }
}

final paymentRepositoryProvider = Provider((ref) {
  final s = ref.watch(authSessionProvider);
  return PaymentRepository(
    ref.watch(firestoreProvider),
    s.userId,
    s.role ?? UserRole.customer,
  );
});
final invoicePageProvider = FutureProvider.autoDispose
    .family<RecordPage<Invoice>, InvoiceFilter>(
      (ref, f) => ref.watch(paymentRepositoryProvider).list(f),
    );
final invoiceProvider = StreamProvider.autoDispose.family<Invoice?, String>(
  (ref, id) => ref
      .watch(paymentRepositoryProvider)
      .invoices
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Invoice(s.id, s.data()!) : null),
);
