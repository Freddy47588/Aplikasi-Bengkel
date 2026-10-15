import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../constants/user_role.dart';
import '../models/inventory.dart';
import '../models/service_order.dart';
import 'firebase_providers.dart';

abstract class InventoryRepository {
  String newOperationId();
  Future<RecordPage<Sparepart>> list(InventoryFilter filter);
  Future<Sparepart?> get(String sku);
  Future<void> save(SparepartDraft draft, {int? expectedVersion});
  Future<StockMovement> post(MovementCommand command);
  Future<StockMovement> reverse(String movementId, String reason);
  Future<RecordPage<StockMovement>> ledger(LedgerFilter filter);
  Future<RecordPage<Map<String, dynamic>>> orderRecords(
    OrderInventoryFilter filter,
  );
  Future<void> requestPart(
    String id,
    String orderId,
    String sku,
    int quantity,
    String reason,
  );
  Future<void> decideRequest(
    String orderId,
    String requestId, {
    required bool approve,
    required String reason,
  });
}

class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository(this.db, this.uid, this.role);
  final FirebaseFirestore db;
  final String uid;
  final UserRole role;
  static const pageSize = 20;
  FieldValue get now => FieldValue.serverTimestamp();
  void adminOnly() {
    if (role != UserRole.admin) throw StateError('Akses admin diperlukan.');
  }

  @override
  String newOperationId() => db.collection('stockMovements').doc().id;
  @override
  Future<RecordPage<Sparepart>> list(InventoryFilter filter) async {
    adminOnly();
    Query<Map<String, dynamic>> q = db.collection('spareparts');
    if (filter.active != null) q = q.where('active', isEqualTo: filter.active);
    if (filter.category.isNotEmpty) {
      q = q.where('category', isEqualTo: filter.category);
    }
    if (filter.lowOnly) q = q.where('lowStock', isEqualTo: true);
    final prefix = canonicalSku(filter.search);
    if (prefix.isNotEmpty) {
      q = q
          .where('sku', isGreaterThanOrEqualTo: prefix)
          .where('sku', isLessThanOrEqualTo: '$prefix\uf8ff');
    }
    q = q.orderBy('sku');
    if (filter.cursor != null) q = q.startAfterDocument(filter.cursor!);
    final s = await q.limit(pageSize).get();
    return RecordPage(
      s.docs.map((d) => Sparepart(d.id, d.data())).toList(),
      s.docs.lastOrNull,
      s.docs.length == pageSize,
    );
  }

  @override
  Future<Sparepart?> get(String sku) async {
    adminOnly();
    final d = await db.collection('spareparts').doc(canonicalSku(sku)).get();
    return d.exists ? Sparepart(d.id, d.data()!) : null;
  }

  @override
  Future<void> save(SparepartDraft draft, {int? expectedVersion}) async {
    adminOnly();
    draft.validate();
    final ref = db.collection('spareparts').doc(canonicalSku(draft.sku));
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      if (old.exists != (expectedVersion != null) ||
          (old.exists && old['version'] != expectedVersion)) {
        throw StateError('SKU sudah ada atau data berubah. Muat ulang.');
      }
      final stock = old.data()?['stock'] as int? ?? 0;
      final fields = {
        ...draft.toMap(),
        'lowStock': stock <= draft.minimumStock,
        'updatedAt': now,
        'updatedBy': uid,
        'version': (expectedVersion ?? -1) + 1,
      };
      if (old.exists) {
        tx.update(ref, fields);
      } else {
        tx.set(ref, {
          ...fields,
          'stock': 0,
          'stockRevision': 0,
          'lastMovementId': null,
          'createdAt': now,
          'createdBy': uid,
        });
      }
    });
  }

  @override
  Future<StockMovement> post(MovementCommand c) async {
    adminOnly();
    c.validate();
    final movement = db.collection('stockMovements').doc(c.id);
    return db.runTransaction((tx) async {
      final existing = await tx.get(movement);
      if (existing.exists) {
        final d = existing.data()!;
        if (d['sku'] != c.sku ||
            d['kind'] != c.kind.name ||
            d['quantity'] != c.quantity ||
            d['reason'] != c.reason.trim() ||
            d['serviceOrderId'] != c.serviceOrderId ||
            d['requestId'] != c.requestId ||
            d['reversalOf'] != c.reversalOf ||
            (c.kind != MovementKind.reversal && d['delta'] != c.delta)) {
          throw StateError('ID operasi sudah dipakai untuk isi berbeda.');
        }
        return StockMovement(existing.id, d);
      }
      final partRef = db.collection('spareparts').doc(c.sku);
      final p = await tx.get(partRef);
      if (!p.exists) throw StateError('SKU tidak ditemukan.');
      Map<String, dynamic>? original;
      if (c.kind == MovementKind.reversal) {
        final old = await tx.get(
          db.collection('stockMovements').doc(c.reversalOf),
        );
        original = old.data();
        if (original == null ||
            original['kind'] == 'reversal' ||
            original['sku'] != c.sku ||
            original['quantity'] != c.quantity ||
            original['serviceOrderId'] != c.serviceOrderId ||
            c.requestId != null) {
          throw StateError('Reversal tidak cocok dengan movement asli.');
        }
      }
      if (c.kind == MovementKind.usage || original?['kind'] == 'usage') {
        final so = await tx.get(
          db.collection('serviceOrders').doc(c.serviceOrderId),
        );
        if (!so.exists || terminalOrder(so['status'] as String)) {
          throw StateError('Service Order tidak aktif.');
        }
      }
      DocumentReference<Map<String, dynamic>>? requestRef;
      if (c.requestId != null) {
        requestRef = db
            .collection('serviceOrders')
            .doc(c.serviceOrderId)
            .collection('partRequests')
            .doc(c.requestId);
        final request = await tx.get(requestRef);
        if (!request.exists ||
            request['status'] != 'pending' ||
            request['sku'] != c.sku ||
            request['quantity'] != c.quantity) {
          throw StateError('Permintaan berubah atau sudah diproses.');
        }
      }
      if (c.kind != MovementKind.reversal && p['active'] != true) {
        throw StateError('Sparepart nonaktif.');
      }
      final delta = original == null ? c.delta : -(original['delta'] as int);
      final before = p['stock'] as int, after = before + delta;
      if (after < 0 || after > maxStock) {
        throw StateError('Stok tidak cukup atau melewati batas.');
      }
      final data = <String, dynamic>{
        'sku': c.sku,
        'kind': c.kind.name,
        'quantity': c.quantity,
        'delta': delta,
        'reason': c.reason.trim(),
        'serviceOrderId': c.serviceOrderId,
        'requestId': c.requestId,
        'reversalOf': c.reversalOf,
        'balanceBefore': before,
        'balanceAfter': after,
        'stockRevision': (p['stockRevision'] as int) + 1,
        'name': original?['name'] ?? p['name'],
        'unit': original?['unit'] ?? p['unit'],
        'buyPrice': original?['buyPrice'] ?? p['buyPrice'],
        'sellPrice': original?['sellPrice'] ?? p['sellPrice'],
        'actorId': uid,
        'createdAt': now,
      };
      tx.update(partRef, {
        'stock': after,
        'stockRevision': data['stockRevision'],
        'version': (p['version'] as int) + 1,
        'lastMovementId': c.id,
        'lowStock': after <= (p['minimumStock'] as int),
        'updatedAt': now,
        'updatedBy': uid,
      });
      tx.set(movement, data);
      if (c.kind == MovementKind.usage ||
          (original != null && original['kind'] == 'usage')) {
        tx.set(
          db
              .collection('serviceOrders')
              .doc(c.serviceOrderId)
              .collection('partUsages')
              .doc(c.id),
          {
            'movementId': c.id,
            'sku': c.sku,
            'name': data['name'],
            'unit': data['unit'],
            'quantity': c.quantity,
            'sellPrice': data['sellPrice'],
            'kind': c.kind.name,
            'reversalOf': c.reversalOf,
            'actorId': uid,
            'createdAt': now,
          },
        );
      }
      if (requestRef != null) {
        tx.update(requestRef, {
          'status': 'approved',
          'movementId': c.id,
          'decidedBy': uid,
          'decidedAt': now,
          'decisionReason': c.reason.trim(),
        });
      }
      return StockMovement(c.id, data);
    });
  }

  static bool terminalOrder(String status) =>
      ['completed', 'cancelled'].contains(status);
  @override
  Future<StockMovement> reverse(String movementId, String reason) async {
    adminOnly();
    final original = await db
        .collection('stockMovements')
        .doc(movementId)
        .get();
    if (!original.exists || original['kind'] == 'reversal') {
      throw StateError('Movement tidak dapat direversal.');
    }
    return post(
      MovementCommand(
        id: 'R~$movementId',
        sku: original['sku'] as String,
        kind: MovementKind.reversal,
        quantity: original['quantity'] as int,
        reason: reason,
        serviceOrderId: original['serviceOrderId'] as String?,
        reversalOf: movementId,
      ),
    );
  }

  @override
  Future<RecordPage<StockMovement>> ledger(LedgerFilter filter) async {
    adminOnly();
    Query<Map<String, dynamic>> q = db.collection('stockMovements');
    if (filter.sku.isNotEmpty) q = q.where('sku', isEqualTo: filter.sku);
    if (filter.serviceOrderId.isNotEmpty) {
      q = q.where('serviceOrderId', isEqualTo: filter.serviceOrderId);
    }
    q = q.orderBy('createdAt', descending: true).orderBy(FieldPath.documentId);
    if (filter.cursor != null) q = q.startAfterDocument(filter.cursor!);
    final s = await q.limit(pageSize).get();
    return RecordPage(
      s.docs.map((d) => StockMovement(d.id, d.data())).toList(),
      s.docs.lastOrNull,
      s.docs.length == pageSize,
    );
  }

  @override
  Future<RecordPage<Map<String, dynamic>>> orderRecords(
    OrderInventoryFilter filter,
  ) async {
    Query<Map<String, dynamic>> q = db
        .collection('serviceOrders')
        .doc(filter.orderId)
        .collection(filter.requests ? 'partRequests' : 'partUsages')
        .orderBy('createdAt', descending: true)
        .orderBy(FieldPath.documentId);
    if (filter.cursor != null) q = q.startAfterDocument(filter.cursor!);
    final s = await q.limit(pageSize).get();
    return RecordPage(
      s.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      s.docs.lastOrNull,
      s.docs.length == pageSize,
    );
  }

  @override
  Future<void> requestPart(
    String id,
    String orderId,
    String sku,
    int quantity,
    String reason,
  ) async {
    if (role != UserRole.technician ||
        !validSku(canonicalSku(sku)) ||
        quantity <= 0 ||
        quantity > maxQuantity ||
        reason.trim().isEmpty ||
        reason.trim().length > 500) {
      throw ArgumentError('Permintaan tidak valid.');
    }
    final ref = db
        .collection('serviceOrders')
        .doc(orderId)
        .collection('partRequests')
        .doc(id);
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      final so = await tx.get(db.collection('serviceOrders').doc(orderId));
      if (old.exists) {
        if (old['sku'] != canonicalSku(sku) ||
            old['quantity'] != quantity ||
            old['reason'] != reason.trim() ||
            old['createdBy'] != uid) {
          throw StateError('ID permintaan sudah digunakan.');
        }
        return;
      }
      if (!so.exists ||
          so['technicianId'] != uid ||
          !['inProgress', 'paused'].contains(so['status'])) {
        throw StateError('Mulai tugas sendiri sebelum meminta sparepart.');
      }
      tx.set(ref, {
        'sku': canonicalSku(sku),
        'quantity': quantity,
        'reason': reason.trim(),
        'status': 'pending',
        'createdBy': uid,
        'createdAt': now,
        'decidedBy': null,
        'decidedAt': null,
        'decisionReason': '',
        'movementId': null,
      });
    });
  }

  @override
  Future<void> decideRequest(
    String orderId,
    String requestId, {
    required bool approve,
    required String reason,
  }) async {
    adminOnly();
    if (reason.trim().isEmpty || reason.trim().length > 500) {
      throw ArgumentError('Alasan keputusan wajib.');
    }
    final ref = db
        .collection('serviceOrders')
        .doc(orderId)
        .collection('partRequests')
        .doc(requestId);
    if (approve) {
      final r = await ref.get();
      if (!r.exists) throw StateError('Permintaan tidak ditemukan.');
      await post(
        MovementCommand(
          id: 'Q~$orderId~$requestId',
          sku: r['sku'] as String,
          kind: MovementKind.usage,
          quantity: r['quantity'] as int,
          reason: reason,
          serviceOrderId: orderId,
          requestId: requestId,
        ),
      );
    } else {
      await db.runTransaction((tx) async {
        final r = await tx.get(ref);
        if (!r.exists) throw StateError('Permintaan tidak ditemukan.');
        if (r['status'] == 'rejected' && r['decisionReason'] == reason.trim()) {
          return;
        }
        if (r['status'] != 'pending') {
          throw StateError('Permintaan sudah diproses.');
        }
        tx.update(ref, {
          'status': 'rejected',
          'decidedBy': uid,
          'decidedAt': now,
          'decisionReason': reason.trim(),
        });
      });
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final s = ref.watch(authSessionProvider);
  return FirestoreInventoryRepository(
    ref.watch(firestoreProvider),
    s.userId,
    s.role ?? UserRole.customer,
  );
});
final inventoryPageProvider = FutureProvider.autoDispose
    .family<RecordPage<Sparepart>, InventoryFilter>(
      (ref, filter) => ref.watch(inventoryRepositoryProvider).list(filter),
    );
final sparepartProvider = FutureProvider.autoDispose.family<Sparepart?, String>(
  (ref, sku) => ref.watch(inventoryRepositoryProvider).get(sku),
);
final ledgerPageProvider = FutureProvider.autoDispose
    .family<RecordPage<StockMovement>, LedgerFilter>(
      (ref, filter) => ref.watch(inventoryRepositoryProvider).ledger(filter),
    );
final orderInventoryProvider = FutureProvider.autoDispose
    .family<RecordPage<Map<String, dynamic>>, OrderInventoryFilter>(
      (ref, filter) =>
          ref.watch(inventoryRepositoryProvider).orderRecords(filter),
    );
