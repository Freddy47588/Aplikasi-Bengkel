import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/inventory_repository.dart';
import 'package:bengkel_kendaraan/core/data/service_history_repository.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/models/inventory.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:bengkel_kendaraan/core/models/service_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreServiceHistoryRepository history;
  setUp(() {
    db = FakeFirebaseFirestore();
    history = FirestoreServiceHistoryRepository(db, 'a', UserRole.customer);
  });
  test(
    'completed-only, scoped filters, WIB boundaries and tied-date cursor pagination',
    () async {
      final date = wibDay(DateTime(2026, 10, 15));
      for (var i = 0; i < 47; i++) {
        await db.doc('serviceOrders/o${i.toString().padLeft(2, '0')}').set({
          'status': i == 46 ? 'awaitingApproval' : 'completed',
          'customerId': i == 45 ? 'b' : 'a',
          'technicianId': i == 44 ? 'tb' : 'ta',
          'vehicleId': i == 43 ? 'v2' : 'v',
          'serviceId': i == 42 ? 'brake' : 'oil',
          'completedAt': Timestamp.fromDate(date),
        });
      }
      await db.doc('serviceOrders/old').set({
        'status': 'completed',
        'customerId': 'a',
        'vehicleId': 'v',
        'serviceId': 'oil',
        'completedAt': Timestamp.fromDate(
          date.subtract(const Duration(seconds: 1)),
        ),
      });
      await db.doc('serviceOrders/next-day').set({
        'status': 'completed',
        'customerId': 'a',
        'vehicleId': 'v',
        'serviceId': 'oil',
        'completedAt': Timestamp.fromDate(date.add(const Duration(days: 1))),
      });
      HistoryFilter filter([DocumentSnapshot<Map<String, dynamic>>? cursor]) =>
          HistoryFilter(
            vehicleId: 'v',
            serviceId: 'oil',
            from: date,
            until: date.add(const Duration(days: 1)),
            cursor: cursor,
          );
      final one = await history.watch(filter()).first;
      final two = await history.watch(filter(one.cursor)).first;
      final three = await history.watch(filter(two.cursor)).first;
      expect(
        [one.items.length, two.items.length, three.items.length],
        [20, 20, 3],
      );
      expect(
        {
          ...one.items.map((o) => o.id),
          ...two.items.map((o) => o.id),
          ...three.items.map((o) => o.id),
        }.length,
        43,
      );
      expect(three.hasMore, false);
      final tech = FirestoreServiceHistoryRepository(
        db,
        'tb',
        UserRole.technician,
      );
      expect(
        (await tech.watch(const HistoryFilter()).first).items.single.id,
        'o44',
      );
      expect(wibDay(DateTime(2026, 10, 15)), DateTime.utc(2026, 10, 14, 17));
      expect(
        () => history.watch(HistoryFilter(from: date, until: date)),
        throwsArgumentError,
      );
      await expectLater(history.parts('o46'), throwsStateError);
      await expectLater(history.parts('o45'), throwsStateError);
    },
  );

  test(
    'canonical completion freezes service, technician and part snapshots including reversals',
    () async {
      final admin = FirestoreServiceOrderRepository(
        db,
        'admin',
        UserRole.admin,
      );
      final tech = FirestoreServiceOrderRepository(
        db,
        'ta',
        UserRole.technician,
      );
      final inventory = FirestoreInventoryRepository(
        db,
        'admin',
        UserRole.admin,
      );
      await db.doc('users/ta').set({'role': 'technician', 'active': true});
      await admin.saveTechnician('ta', 'Ari', 'Mesin', true, true);
      await db.doc('bookings/one').set({
        'status': 'confirmed',
        'customerId': 'a',
        'vehicleId': 'v',
        'vehicleName': 'Brio',
        'vehiclePlate': 'B 1 AA',
        'serviceId': 'oil',
        'serviceName': 'Ganti oli',
        'complaint': 'Mesin berisik',
        'scheduledAt': Timestamp.now(),
      });
      await admin.create('one');
      await admin.assign('one', 'ta', 0);
      Future<ServiceOrder> read() async => ServiceOrder(
        'one',
        (await db.doc('serviceOrders/one').get()).data()!,
      );
      Future<void> change(
        FirestoreServiceOrderRepository repo,
        ServiceOrderStatus status,
      ) async {
        final o = await read();
        await repo.updateWork(
          'one',
          o.revision,
          status: status,
          checklist: {for (final k in inspectionKeys) k: true},
          diagnosis: 'Oli kotor',
          actions: 'Ganti oli',
          notes: '',
        );
      }

      await change(tech, ServiceOrderStatus.inProgress);
      SparepartDraft part(int price) => SparepartDraft(
        sku: 'OIL',
        name: 'Oli',
        category: 'Pelumas',
        unit: 'botol',
        buyPrice: 40000,
        sellPrice: price,
        minimumStock: 1,
      );
      await inventory.save(part(55000));
      await inventory.post(
        const MovementCommand(
          id: 'receipt',
          sku: 'OIL',
          kind: MovementKind.receipt,
          quantity: 5,
          reason: 'Beli',
        ),
      );
      for (final id in ['used', 'return']) {
        await inventory.post(
          MovementCommand(
            id: id,
            sku: 'OIL',
            kind: MovementKind.usage,
            quantity: 1,
            reason: 'Ganti',
            serviceOrderId: 'one',
          ),
        );
      }
      await inventory.reverse('return', 'Tidak terpakai');
      await change(tech, ServiceOrderStatus.awaitingApproval);
      await expectLater(
        change(admin, ServiceOrderStatus.completed),
        throwsStateError,
      );
      await expectLater(
        tech.setLaborPrice('one', (await read()).revision, 1),
        throwsStateError,
      );
      await admin.setLaborPrice('one', (await read()).revision, 75000);
      await expectLater(admin.setLaborPrice('one', 0, 2), throwsStateError);
      await change(admin, ServiceOrderStatus.completed);
      expect(
        (await history.watch(const HistoryFilter()).first).items.single.id,
        'one',
      );
      final parts = await history.parts('one');
      expect(parts.subtotal, 55000);
      final version = (await inventory.get('OIL'))!.version;
      await inventory.save(part(99000), expectedVersion: version);
      await admin.saveTechnician('ta', 'Nama baru', 'Mesin', true, true);
      expect((await read()).text('technicianName'), 'Ari');
      expect((await read()).data['laborPrice'], 75000);
      expect((await history.parts('one')).subtotal, 55000);
      await expectLater(
        inventory.reverse('used', 'Terlambat'),
        throwsStateError,
      );
      await expectLater(
        admin.setLaborPrice('one', (await read()).revision, 1),
        throwsStateError,
      );
      expect(parts.subtotal + (await read()).data['laborPrice'], 130000);
    },
  );

  test(
    'detail totals include all sales-line pages, without master-price joins',
    () async {
      await db.doc('serviceOrders/one').set({
        'status': 'completed',
        'customerId': 'a',
      });
      for (var i = 0; i < 43; i++) {
        await db.doc('serviceOrders/one/partUsages/p$i').set({
          'kind': 'usage',
          'quantity': 2,
          'sellPrice': 1000,
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(i),
        });
      }
      final result = await history.parts('one');
      expect(result.lines.length, 43);
      expect(result.subtotal, 86000);
    },
  );

  test(
    'explicit booking and SO timeline maps intermediate and terminal states',
    () {
      expect(
        ServiceTracking.from(BookingStatus.pending, null).stage,
        TrackingStage.pending,
      );
      expect(
        ServiceTracking.from(BookingStatus.confirmed, null).stage,
        TrackingStage.confirmed,
      );
      const expected = [
        TrackingStage.confirmed,
        TrackingStage.assigned,
        TrackingStage.inProgress,
        TrackingStage.inProgress,
        TrackingStage.inProgress,
        TrackingStage.completed,
        TrackingStage.confirmed,
      ];
      for (final status in ServiceOrderStatus.values) {
        final tracking = ServiceTracking.from(
          BookingStatus.confirmed,
          ServiceOrder('x', {'status': status.name}),
        );
        expect(tracking.stage, expected[status.index]);
        expect(tracking.stopped, status == ServiceOrderStatus.cancelled);
      }
      expect(ServiceTracking.from(BookingStatus.rejected, null).stopped, true);
      expect(ServiceTracking.from(BookingStatus.cancelled, null).stopped, true);
      expect(
        historyDate(DateTime.utc(2026, 10, 14, 18, 5)),
        '15/10/2026 01:05 WIB',
      );
      expect(rupiah(130000), 'Rp 130.000');
    },
  );
}
