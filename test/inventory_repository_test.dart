import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

SparepartDraft draft({
  String sku = 'OIL',
  int sellPrice = 55000,
  bool active = true,
}) => SparepartDraft(
  sku: sku,
  name: 'Oli mesin',
  category: 'Pelumas',
  unit: 'botol',
  buyPrice: 40000,
  sellPrice: sellPrice,
  minimumStock: 2,
  active: active,
);
MovementCommand command(
  String id, {
  MovementKind kind = MovementKind.receipt,
  int quantity = 5,
  String reason = 'Pembelian',
  String? so,
  bool decrease = false,
}) => MovementCommand(
  id: id,
  sku: 'OIL',
  kind: kind,
  quantity: quantity,
  reason: reason,
  serviceOrderId: so,
  decrease: decrease,
);

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreInventoryRepository admin, tech, customer;
  setUp(() async {
    db = FakeFirebaseFirestore();
    admin = FirestoreInventoryRepository(db, 'admin', UserRole.admin);
    tech = FirestoreInventoryRepository(db, 'ta', UserRole.technician);
    customer = FirestoreInventoryRepository(db, 'customer', UserRole.customer);
    await db.doc('serviceOrders/so').set({
      'customerId': 'customer',
      'technicianId': 'ta',
      'status': 'inProgress',
    });
    await admin.save(draft(sku: ' oil '));
  });
  test(
    'master SKU canonical and unique; archive keeps history, stale versions and negative price rejected',
    () async {
      expect((await admin.get('oil'))!.id, 'OIL');
      await expectLater(admin.save(draft()), throwsStateError);
      expect(() => draft(sellPrice: -1).validate(), throwsArgumentError);
      await admin.post(command('receipt'));
      await expectLater(
        admin.save(draft(sellPrice: 60000), expectedVersion: 0),
        throwsStateError,
      );
      await admin.save(draft(active: false), expectedVersion: 1);
      expect((await admin.get('OIL'))!.stock, 5);
      await expectLater(admin.post(command('blocked')), throwsStateError);
      expect(
        (await admin.ledger((
          cursor: null,
          sku: 'OIL',
          serviceOrderId: '',
        ))).items.length,
        1,
      );
      await expectLater(tech.save(draft(sku: 'OTHER')), throwsStateError);
      await expectLater(customer.get('OIL'), throwsStateError);
    },
  );
  test(
    '5 - usage 2 = 3 plus ledger and sales snapshot; same operation retry never decrements twice',
    () async {
      await admin.post(command('receipt'));
      final use = command(
        'use',
        kind: MovementKind.usage,
        quantity: 2,
        so: 'so',
      );
      await admin.post(use);
      await admin.post(use);
      expect((await admin.get('OIL'))!.stock, 3);
      expect((await db.doc('stockMovements/use').get())['balanceBefore'], 5);
      expect((await db.doc('stockMovements/use').get())['balanceAfter'], 3);
      final line = (await db.doc('serviceOrders/so/partUsages/use').get())
          .data()!;
      expect(line['quantity'], 2);
      expect(line['sellPrice'], 55000);
      expect(line.containsKey('buyPrice'), false);
      await expectLater(
        admin.post(
          command('use', kind: MovementKind.usage, quantity: 1, so: 'so'),
        ),
        throwsStateError,
      );
      await expectLater(
        admin.post(
          command('too-much', kind: MovementKind.usage, quantity: 6, so: 'so'),
        ),
        throwsStateError,
      );
      expect((await admin.get('OIL'))!.stock, 3);
      expect((await db.doc('stockMovements/too-much').get()).exists, false);
      await expectLater(tech.post(use), throwsStateError);
    },
  );
  test(
    'reversal is full, idempotent, immutable-source prices and cannot oversell or reverse reversal',
    () async {
      await admin.post(command('receipt'));
      await admin.post(
        command('use', kind: MovementKind.usage, quantity: 2, so: 'so'),
      );
      await expectLater(admin.reverse('receipt', 'Ralat'), throwsStateError);
      await admin.save(
        draft(sellPrice: 65000, active: false),
        expectedVersion: 2,
      );
      await admin.reverse('use', 'Barang dikembalikan');
      await admin.reverse('use', 'Barang dikembalikan');
      expect((await admin.get('OIL'))!.stock, 5);
      expect((await db.doc('stockMovements/R~use').get())['sellPrice'], 55000);
      expect(
        (await db.doc('serviceOrders/so/partUsages/R~use').get())['reversalOf'],
        'use',
      );
      await expectLater(admin.reverse('R~use', 'Ralat'), throwsStateError);
      await expectLater(
        admin.reverse('use', 'Alasan berbeda'),
        throwsStateError,
      );
      await admin.reverse('receipt', 'Ralat pembelian');
      expect((await admin.get('OIL'))!.stock, 0);
      expect((await db.doc('stockMovements/receipt').get())['quantity'], 5);
    },
  );
  test(
    'technician request approval/rejection idempotent, never changes stock before approval',
    () async {
      await admin.post(command('receipt'));
      await tech.requestPart('req', 'so', 'oil', 2, 'Ganti oli');
      await tech.requestPart('req', 'so', 'oil', 2, 'Ganti oli');
      expect((await admin.get('OIL'))!.stock, 5);
      final other = FirestoreInventoryRepository(db, 'tb', UserRole.technician);
      await expectLater(
        other.requestPart('hijack', 'so', 'OIL', 2, 'Ganti'),
        throwsStateError,
      );
      await admin.decideRequest('so', 'req', approve: true, reason: 'Setuju');
      await admin.decideRequest('so', 'req', approve: true, reason: 'Setuju');
      expect((await admin.get('OIL'))!.stock, 3);
      expect(
        (await db.doc('serviceOrders/so/partRequests/req').get())['movementId'],
        'Q~so~req',
      );
      await expectLater(
        admin.decideRequest('so', 'req', approve: false, reason: 'Tolak'),
        throwsStateError,
      );
      await tech.requestPart('req2', 'so', 'OIL', 1, 'Cadangan');
      await admin.decideRequest(
        'so',
        'req2',
        approve: false,
        reason: 'Tidak perlu',
      );
      await admin.decideRequest(
        'so',
        'req2',
        approve: false,
        reason: 'Tidak perlu',
      );
      expect((await admin.get('OIL'))!.stock, 3);
      await db.doc('serviceOrders/so').update({'status': 'completed'});
      await expectLater(
        tech.requestPart('closed', 'so', 'OIL', 1, 'Ganti'),
        throwsStateError,
      );
    },
  );
  test(
    'correction, quantity bounds and derived low-stock never drift',
    () async {
      await admin.post(command('receipt'));
      await admin.post(
        command(
          'loss',
          kind: MovementKind.adjustment,
          quantity: 3,
          decrease: true,
          reason: 'Rusak',
        ),
      );
      final part = (await admin.get('OIL'))!;
      expect(part.stock, 2);
      expect(part.lowStock, true);
      await admin.reverse('loss', 'Salah hitung');
      expect((await admin.get('OIL'))!.lowStock, false);
      for (final quantity in [0, -1, maxQuantity + 1]) {
        await expectLater(
          admin.post(command('bad', quantity: quantity)),
          throwsArgumentError,
        );
      }
      await expectLater(
        admin.post(command('bad', reason: ' ')),
        throwsArgumentError,
      );
      expect((await db.doc('stockMovements/bad').get()).exists, false);
    },
  );
  test(
    'bounded cursor pagination, search, category, active and low-stock query all records',
    () async {
      for (var i = 0; i < 42; i++) {
        await admin.save(draft(sku: 'PART-${i.toString().padLeft(3, '0')}'));
      }
      const filter = (
        cursor: null,
        search: 'part-',
        category: 'Pelumas',
        active: true,
        lowOnly: true,
      );
      final first = await admin.list(filter);
      final next = await admin.list((
        cursor: first.cursor,
        search: filter.search,
        category: filter.category,
        active: filter.active,
        lowOnly: filter.lowOnly,
      ));
      final last = await admin.list((
        cursor: next.cursor,
        search: filter.search,
        category: filter.category,
        active: filter.active,
        lowOnly: filter.lowOnly,
      ));
      expect(
        [first.items.length, next.items.length, last.items.length],
        [20, 20, 2],
      );
      expect(
        {
          ...first.items.map((p) => p.id),
          ...next.items.map((p) => p.id),
          ...last.items.map((p) => p.id),
        }.length,
        42,
      );
      final batch = db.batch();
      for (var i = 0; i < 25; i++) {
        batch.set(db.doc('stockMovements/m$i'), {
          'sku': 'OIL',
          'serviceOrderId': 'so',
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(i),
        });
      }
      await batch.commit();
      final ledger = await admin.ledger((
        cursor: null,
        sku: 'OIL',
        serviceOrderId: 'so',
      ));
      final ledger2 = await admin.ledger((
        cursor: ledger.cursor,
        sku: 'OIL',
        serviceOrderId: 'so',
      ));
      expect([ledger.items.length, ledger2.items.length], [20, 5]);
    },
  );
}
