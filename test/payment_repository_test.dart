import 'dart:convert';
import 'dart:io';
import 'package:bengkel_kendaraan/core/constants/user_role.dart';
import 'package:bengkel_kendaraan/core/data/payment_repository.dart';
import 'package:bengkel_kendaraan/core/data/report_repository.dart';
import 'package:bengkel_kendaraan/core/data/invoice_pdf.dart';
import 'package:bengkel_kendaraan/core/models/invoice.dart';
import 'package:bengkel_kendaraan/core/models/service_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late PaymentRepository repo;
  Future<Invoice> read() async =>
      Invoice('so', (await db.doc('invoices/so').get()).data()!);
  setUp(() async {
    db = FakeFirebaseFirestore();
    repo = PaymentRepository(db, 'admin', UserRole.admin);
    await db.doc('serviceOrders/so').set({
      'status': 'completed',
      'customerId': 'customer',
      'serviceName': 'Ganti oli',
      'vehiclePlate': 'B 1234 AA',
      'laborPrice': 75000,
    });
    for (var i = 0; i < 3; i++) {
      await db.doc('serviceOrders/so/partUsages/p$i').set({
        'quantity': 2,
        'sellPrice': 55000,
        'kind': i == 2 ? 'reversal' : 'usage',
        'name': 'Oli',
        'createdAt': Timestamp.now(),
      });
    }
  });
  test(
    'integer totals include parts reversals discount and authorized fee',
    () async {
      await repo.create(
        'so',
        discount: 5000,
        fee: 10000,
        reason: 'Otorisasi admin',
      );
      final i = await read();
      expect(i.number('partSubtotal'), 110000);
      expect(i.number('subtotal'), 185000);
      expect(i.number('grandTotal'), 190000);
      expect(i.number('due'), 190000);
      expect(() => InvoiceTotals(10, [], 11, 0), throwsArgumentError);
      expect(() => InvoiceTotals(-1, [], 0, 0), throwsArgumentError);
    },
  );
  test(
    'one invoice per SO and snapshot survives master price changes',
    () async {
      await repo.create('so', reason: 'Final');
      await db.doc('spareparts/OIL').set({'sellPrice': 999999});
      await db.doc('services/oil').set({'price': 999999});
      await repo.create('so', discount: 1000, reason: 'Retry');
      expect((await repo.invoices.get()).docs, hasLength(1));
      expect((await read()).number('grandTotal'), 185000);
      expect((await read()).data['parts'][0]['sellPrice'], 55000);
    },
  );
  test(
    'double submit key and stale revision cannot double-charge; cash change',
    () async {
      await repo.create('so', reason: 'Final');
      Future<void> pay() => repo.record(
        'so',
        'stable_key_0001',
        0,
        kind: 'payment',
        amount: 50000,
        method: 'cash',
        reason: 'Diterima',
      );
      await pay();
      await pay();
      expect((await read()).number('paidAmount'), 50000);
      expect((await read()).text('status'), 'partial');
      expect(
        (await repo.invoices.doc('so').collection('payments').get()).docs,
        hasLength(2),
      );
      await expectLater(
        repo.record(
          'so',
          'stable_key_0001',
          1,
          kind: 'payment',
          amount: 1,
          method: 'cash',
          reason: 'Diterima',
        ),
        throwsStateError,
      );
      await expectLater(
        repo.record(
          'so',
          'different_key_01',
          0,
          kind: 'payment',
          amount: 50000,
          method: 'cash',
          reason: 'Diterima',
        ),
        throwsStateError,
      );
      await repo.record(
        'so',
        'stable_key_0002',
        1,
        kind: 'payment',
        amount: 150000,
        method: 'cash',
        reason: 'Pelunasan',
      );
      expect((await read()).number('change'), 15000);
      expect((await read()).number('due'), 0);
      expect((await read()).text('status'), 'paid');
      await expectLater(
        repo.record(
          'so',
          'stable_key_0003',
          2,
          kind: 'payment',
          amount: 1,
          method: 'cash',
          reason: 'Lagi',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'transfer cannot overpay; void/refund transitions and full audit',
    () async {
      await repo.create('so', reason: 'Final');
      await expectLater(
        repo.record(
          'so',
          'stable_key_0001',
          0,
          kind: 'payment',
          amount: 190000,
          method: 'transfer',
          reason: 'Cek rekening',
        ),
        throwsStateError,
      );
      await repo.record(
        'so',
        'stable_key_0001',
        0,
        kind: 'payment',
        amount: 10000,
        method: 'transfer',
        reason: 'Terverifikasi manual',
      );
      await expectLater(
        repo.record('so', 'stable_key_0002', 1, kind: 'void', reason: 'Salah'),
        throwsStateError,
      );
      await repo.record(
        'so',
        'stable_key_0002',
        1,
        kind: 'refund',
        amount: 10000,
        method: 'transfer',
        reason: 'Uang sudah dikembalikan',
      );
      expect((await read()).text('status'), 'refunded');
      expect((await read()).number('paidAmount'), 0);
      await expectLater(
        repo.record(
          'so',
          'stable_key_0003',
          2,
          kind: 'refund',
          amount: 10000,
          method: 'transfer',
          reason: 'Lagi',
        ),
        throwsStateError,
      );
    },
  );
  test('customer cannot record, issue, or load admin reports', () async {
    final customer = PaymentRepository(db, 'customer', UserRole.customer);
    await expectLater(customer.create('so', reason: 'Tidak'), throwsStateError);
    await expectLater(
      customer.record(
        'so',
        'stable_key_0001',
        0,
        kind: 'payment',
        amount: 1,
        method: 'cash',
        reason: 'Tidak',
      ),
      throwsStateError,
    );
    await expectLater(
      ReportRepository(
        db,
        UserRole.customer,
      ).load(DateTime.utc(2026), DateTime.utc(2026, 1, 2)),
      throwsStateError,
    );
  });
  test(
    'report excludes unpaid and partial; includes only paid in selected settlement dates',
    () async {
      await repo.create('so', reason: 'Final');
      final reports = ReportRepository(db, UserRole.admin);
      final from = DateTime.utc(2020), until = DateTime.utc(2030);
      Future<int> revenue() async {
        final now = DateTime.now().toUtc();
        return (await reports.load(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        )).revenue;
      }

      expect(await revenue(), 0);
      await repo.record(
        'so',
        'stable_key_0001',
        0,
        kind: 'payment',
        amount: 10000,
        method: 'cash',
        reason: 'Sebagian',
      );
      expect(await revenue(), 0);
      await repo.record(
        'so',
        'stable_key_0002',
        1,
        kind: 'payment',
        amount: 175000,
        method: 'transfer',
        reason: 'Cek manual',
      );
      expect(await revenue(), 185000);
      await repo.record(
        'so',
        'stable_key_0003',
        2,
        kind: 'refund',
        amount: 185000,
        method: 'cash',
        reason: 'Refund penuh',
      );
      expect(await revenue(), 0);
      await expectLater(reports.load(from, until), throwsArgumentError);
    },
  );
  test(
    'report pages real records, nets reversal and counts active low stock',
    () async {
      final at = Timestamp.fromDate(DateTime.utc(2026, 10, 15, 4));
      for (var n = 0; n < 23; n++) {
        await db.doc('bookings/b$n').set({'createdAt': at});
        await db.doc('serviceOrders/done$n').set({
          'status': 'completed',
          'completedAt': at,
        });
        await db.doc('stockMovements/m$n').set({
          'createdAt': at,
          'serviceOrderId': 'so',
          'delta': -2,
        });
      }
      await db.doc('stockMovements/reversal').set({
        'createdAt': at,
        'serviceOrderId': 'so',
        'delta': 2,
      });
      await db.doc('stockMovements/receipt').set({
        'createdAt': at,
        'serviceOrderId': null,
        'delta': 100,
      });
      await db.doc('spareparts/LOW').set({
        'sku': 'LOW',
        'active': true,
        'lowStock': true,
      });
      await db.doc('spareparts/OFF').set({
        'sku': 'OFF',
        'active': false,
        'lowStock': true,
      });
      final result = await ReportRepository(
        db,
        UserRole.admin,
      ).load(wibDay(DateTime(2026, 10, 15)), wibDay(DateTime(2026, 10, 16)));
      expect(result.bookings, 23);
      expect(result.completed, 23);
      expect(result.partUnits, 44);
      expect(result.lowStock, 1);
      expect(result.revenue, 0);
    },
  );
  test(
    'local PDF bytes and WIB formatting independent of input timezone',
    () async {
      await repo.create('so', reason: 'Final');
      final bytes = await buildInvoicePdf(await read());
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      final fixture = File('build/phase06-invoice.pdf');
      await fixture.parent.create(recursive: true);
      await fixture.writeAsBytes(bytes);
      expect(
        historyDate(DateTime.utc(2026, 10, 14, 18, 30)),
        '15/10/2026 01:30 WIB',
      );
      expect(rupiah(1234567), 'Rp 1.234.567');
    },
  );
}
