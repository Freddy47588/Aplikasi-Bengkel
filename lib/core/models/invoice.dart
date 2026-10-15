import 'package:cloud_firestore/cloud_firestore.dart';

const maxInvoiceRupiah = 9000000000000000;

class Invoice {
  Invoice(this.id, Map<String, dynamic> data) : data = Map.unmodifiable(data);
  final String id;
  final Map<String, dynamic> data;
  int number(String key) => data[key] as int;
  String text(String key) => data[key] as String? ?? '';
  DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
}

class InvoiceTotals {
  InvoiceTotals(
    int labor,
    List<Map<String, dynamic>> parts,
    int discount,
    int fee,
  ) {
    if ([labor, discount, fee].any((v) => v < 0 || v > 1000000000)) {
      throw ArgumentError(
        'Harga/diskon/biaya harus integer rupiah nonnegatif.',
      );
    }
    partSubtotal = parts.fold<int>(0, (total, p) {
      final qty = p['quantity'] as int;
      final price = p['sellPrice'] as int;
      if (qty <= 0 ||
          qty > 1000000 ||
          price < 0 ||
          price > 1000000000 ||
          !['usage', 'reversal'].contains(p['kind'])) {
        throw ArgumentError('Snapshot part tidak valid.');
      }
      return total + (p['kind'] == 'reversal' ? -1 : 1) * qty * price;
    });
    subtotal = labor + partSubtotal;
    grandTotal = subtotal - discount + fee;
    if (partSubtotal < 0 || grandTotal <= 0 || grandTotal > maxInvoiceRupiah) {
      throw ArgumentError(
        'Total invoice harus positif dan dalam batas rupiah.',
      );
    }
  }
  late final int partSubtotal, subtotal, grandTotal;
}

typedef InvoiceFilter = ({
  DateTime from,
  DateTime until,
  DocumentSnapshot<Map<String, dynamic>>? cursor,
});
