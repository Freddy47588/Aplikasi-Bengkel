import 'package:cloud_firestore/cloud_firestore.dart';

const maxStock = 1000000000;
const maxQuantity = 1000000;
const maxRupiah = 1000000000;

String canonicalSku(String value) => value.trim().toUpperCase();
bool validSku(String value) =>
    RegExp(r'^[A-Z0-9][A-Z0-9_-]{0,39}$').hasMatch(value);

enum MovementKind {
  receipt('Stok masuk'),
  adjustment('Koreksi'),
  usage('Pemakaian'),
  reversal('Reversal');

  const MovementKind(this.label);
  final String label;
}

class SparepartDraft {
  const SparepartDraft({
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.buyPrice,
    required this.sellPrice,
    required this.minimumStock,
    this.active = true,
    this.supplier = '',
  });
  final String sku, name, category, unit, supplier;
  final int buyPrice, sellPrice, minimumStock;
  final bool active;
  void validate() {
    if (!validSku(canonicalSku(sku)) ||
        name.trim().isEmpty ||
        name.trim().length > 100 ||
        category.trim().isEmpty ||
        category.trim().length > 60 ||
        unit.trim().isEmpty ||
        unit.trim().length > 20 ||
        supplier.trim().length > 160 ||
        buyPrice < 0 ||
        buyPrice > maxRupiah ||
        sellPrice < 0 ||
        sellPrice > maxRupiah ||
        minimumStock < 0 ||
        minimumStock > maxStock) {
      throw ArgumentError(
        'SKU/identitas, harga rupiah integer dan stok minimum tidak valid.',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'sku': canonicalSku(sku),
    'name': name.trim(),
    'category': category.trim(),
    'unit': unit.trim(),
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'minimumStock': minimumStock,
    'active': active,
    'supplier': supplier.trim(),
  };
}

class Sparepart {
  Sparepart(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String text(String key) => data[key] as String;
  int number(String key) => data[key] as int;
  int get stock => number('stock');
  int get version => number('version');
  bool get active => data['active'] == true;
  bool get lowStock => data['lowStock'] == true;
  SparepartDraft get draft => SparepartDraft(
    sku: id,
    name: text('name'),
    category: text('category'),
    unit: text('unit'),
    buyPrice: number('buyPrice'),
    sellPrice: number('sellPrice'),
    minimumStock: number('minimumStock'),
    active: active,
    supplier: text('supplier'),
  );
}

class StockMovement {
  StockMovement(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  MovementKind get kind => MovementKind.values.byName(data['kind'] as String);
  String get sku => data['sku'] as String;
  int get delta => data['delta'] as int;
}

class MovementCommand {
  const MovementCommand({
    required this.id,
    required this.sku,
    required this.kind,
    required this.quantity,
    required this.reason,
    this.decrease = false,
    this.serviceOrderId,
    this.requestId,
    this.reversalOf,
  });
  final String id, sku, reason;
  final MovementKind kind;
  final int quantity;
  final bool decrease;
  final String? serviceOrderId, requestId, reversalOf;
  int get delta =>
      kind == MovementKind.usage ||
          (kind == MovementKind.adjustment && decrease)
      ? -quantity
      : quantity;
  void validate() {
    if (!RegExp(r'^[A-Za-z0-9_~\-]{1,180}$').hasMatch(id) ||
        !validSku(sku) ||
        quantity <= 0 ||
        quantity > maxQuantity ||
        reason.trim().isEmpty ||
        reason.trim().length > 500 ||
        (kind == MovementKind.usage &&
            (serviceOrderId == null || serviceOrderId!.isEmpty)) ||
        (requestId != null && kind != MovementKind.usage) ||
        (kind == MovementKind.reversal &&
            (reversalOf == null || id != 'R~$reversalOf')) ||
        (kind != MovementKind.reversal &&
            (reversalOf != null || id.startsWith('R~') || id.length > 178))) {
      throw ArgumentError(
        'Operasi stok tidak valid. Qty harus integer positif dan alasan wajib.',
      );
    }
  }
}

typedef InventoryFilter = ({
  DocumentSnapshot<Map<String, dynamic>>? cursor,
  String search,
  String category,
  bool? active,
  bool lowOnly,
});
typedef LedgerFilter = ({
  DocumentSnapshot<Map<String, dynamic>>? cursor,
  String sku,
  String serviceOrderId,
});
typedef OrderInventoryFilter = ({
  DocumentSnapshot<Map<String, dynamic>>? cursor,
  String orderId,
  bool requests,
});
