import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/service_order_repository.dart';
import 'package:bengkel_kendaraan/core/data/firestore_booking_repository.dart';
import 'package:bengkel_kendaraan/core/models/booking.dart';
import 'package:bengkel_kendaraan/core/models/service_order.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestoreServiceOrderRepository admin, ta, tb;
  setUp(() async {
    db = FakeFirebaseFirestore();
    admin = FirestoreServiceOrderRepository(db, 'admin', UserRole.admin);
    ta = FirestoreServiceOrderRepository(db, 'ta', UserRole.technician);
    tb = FirestoreServiceOrderRepository(db, 'tb', UserRole.technician);
    for (final id in ['ta', 'tb', 'off']) {
      await db.doc('users/$id').set({'role': 'technician', 'active': true});
      await admin.saveTechnician(id, id, 'Mesin', id != 'off', true);
    }
    for (final id in ['one', 'two', 'pending']) {
      await db.doc('bookings/$id').set({
        'customerId': 'customer',
        'status': id == 'pending' ? 'pending' : 'confirmed',
        'vehicleId': 'v',
        'vehicleName': 'Brio',
        'vehiclePlate': 'B 1234 AA',
        'serviceId': 'oil',
        'serviceName': 'Oli',
        'complaint': 'Mesin bising',
        'scheduledAt': Timestamp.now(),
      });
    }
  });
  Future<ServiceOrder> read(String id) async =>
      ServiceOrder(id, (await db.doc('serviceOrders/$id').get()).data()!);
  Future<void> change(
    FirestoreServiceOrderRepository repo,
    String id,
    ServiceOrderStatus next, {
    bool finished = false,
  }) async {
    final o = await read(id);
    await repo.updateWork(
      id,
      o.revision,
      status: next,
      checklist: {for (final key in inspectionKeys) key: finished},
      diagnosis: finished ? 'Oli kotor' : '',
      actions: finished ? 'Ganti oli' : '',
      notes: 'Catatan',
    );
  }

  test(
    'confirmed-only canonical creation, duplicate rejection and booking cancellation guard',
    () async {
      await expectLater(admin.create('pending'), throwsStateError);
      await admin.create('one');
      await expectLater(admin.create('one'), throwsStateError);
      expect((await read('one')).text('vehiclePlate'), 'B 1234 AA');
      expect(
        (await db.doc('serviceOrders/one/events/0').get())['actorId'],
        'admin',
      );
      await expectLater(ta.create('two'), throwsStateError);
      final customer = FirestoreBookingRepository(
        db,
        uid: 'customer',
        role: UserRole.customer,
      );
      await expectLater(
        customer.updateStatus(
          'one',
          BookingStatus.cancelled,
          actor: UserRole.customer,
          actorId: 'customer',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'inactive/busy technician rejected, idempotency and stale revisions protect reassignment',
    () async {
      await admin.create('one');
      await admin.create('two');
      await expectLater(admin.assign('one', 'off', 0), throwsStateError);
      await admin.assign('one', 'ta', 0);
      await admin.assign('one', 'ta', 0);
      expect((await read('one')).revision, 1);
      await expectLater(admin.assign('two', 'ta', 0), throwsStateError);
      await expectLater(admin.assign('one', 'tb', 0), throwsStateError);
      await expectLater(
        admin.saveTechnician('ta', 'ta', 'Mesin', false, true),
        throwsStateError,
      );
      await admin.assign('one', 'tb', 1);
      expect((await db.doc('technicians/ta').get())['currentOrderId'], isNull);
      await expectLater(
        change(ta, 'one', ServiceOrderStatus.inProgress),
        throwsStateError,
      );
      await change(tb, 'one', ServiceOrderStatus.inProgress);
      await expectLater(admin.assign('one', 'ta', 3), throwsStateError);
    },
  );
  test(
    'start pause resume finish approval preserves source data, timestamps and immutable audit',
    () async {
      await admin.create('one');
      await admin.assign('one', 'ta', 0);
      await expectLater(
        change(tb, 'one', ServiceOrderStatus.inProgress),
        throwsStateError,
      );
      await change(ta, 'one', ServiceOrderStatus.inProgress);
      final started = (await read('one')).date('startedAt');
      await change(ta, 'one', ServiceOrderStatus.paused);
      await change(ta, 'one', ServiceOrderStatus.inProgress);
      expect((await read('one')).date('startedAt'), started);
      await expectLater(
        change(ta, 'one', ServiceOrderStatus.awaitingApproval),
        throwsStateError,
      );
      await change(
        ta,
        'one',
        ServiceOrderStatus.awaitingApproval,
        finished: true,
      );
      await expectLater(
        change(ta, 'one', ServiceOrderStatus.completed),
        throwsStateError,
      );
      await change(admin, 'one', ServiceOrderStatus.completed);
      final order = await read('one');
      expect(order.status, ServiceOrderStatus.completed);
      expect(order.text('diagnosis'), 'Oli kotor');
      expect(order.date('completedAt'), isNotNull);
      expect((await db.doc('technicians/ta').get())['currentOrderId'], isNull);
      expect(
        (await db.collection('serviceOrders/one/events').get()).docs.length,
        order.revision + 1,
      );
      await expectLater(
        change(ta, 'one', ServiceOrderStatus.inProgress),
        throwsStateError,
      );
    },
  );
  test(
    'cursor pagination and role filters cover all orders without overlapping pages',
    () async {
      final batch = db.batch();
      for (var i = 0; i < 45; i++) {
        batch.set(db.doc('serviceOrders/o$i'), {
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(i),
          'customerId': i == 0 ? 'other' : 'customer',
          'technicianId': i.isEven ? 'ta' : 'tb',
        });
      }
      await batch.commit();
      final first = await admin.watchOrders().first;
      final second = await admin.watchOrders(after: first.cursor).first;
      final third = await admin.watchOrders(after: second.cursor).first;
      expect(
        [first.items.length, second.items.length, third.items.length],
        [20, 20, 5],
      );
      expect(
        {
          ...first.items.map((o) => o.id),
          ...second.items.map((o) => o.id),
          ...third.items.map((o) => o.id),
        }.length,
        45,
      );
      expect(third.hasMore, false);
      final own = await ta.watchOrders().first;
      expect(own.items.every((o) => o.technicianId == 'ta'), true);
      final techs = await admin
          .watchTechnicians(search: 't', active: true, specialization: 'Mesin')
          .first;
      expect(techs.items.map((t) => t.id), ['ta', 'tb']);
    },
  );
}
