import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/inventory_repository.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/inventory.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../technician/presentation/service_orders_screen.dart';
import 'inventory_screen.dart';

class OrderPartsScreen extends ConsumerStatefulWidget {
  const OrderPartsScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<OrderPartsScreen> createState() => _OrderPartsState();
}

class _OrderPartsState extends ConsumerState<OrderPartsScreen> {
  bool requests = false;
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    final filter = (
      cursor: cursors.last,
      orderId: widget.orderId,
      requests: requests && role != 'customer',
    );
    final provider = orderInventoryProvider(filter);
    Future<void> open(Widget screen) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      if (mounted) ref.invalidate(provider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sparepart Service Order'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(provider),
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ref
            .watch(serviceOrderProvider(widget.orderId))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => RetryLoad(
                onRetry: () =>
                    ref.invalidate(serviceOrderProvider(widget.orderId)),
              ),
              data: (order) {
                if (order == null) {
                  return const Center(
                    child: Text('Service Order tidak ditemukan.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      '${order.text('vehicleName')} • ${order.status.label}',
                    ),
                    if (role == 'admin') ...[
                      if (!order.status.terminal)
                        FilledButton(
                          onPressed: () =>
                              open(InventoryScreen(orderId: widget.orderId)),
                          child: const Text('Tambah pemakaian sparepart'),
                        ),
                      OutlinedButton(
                        onPressed: () =>
                            open(StockLedgerScreen(orderId: widget.orderId)),
                        child: const Text('Ledger SO'),
                      ),
                    ],
                    if (role == 'technician' &&
                        ['inProgress', 'paused'].contains(order.status.name))
                      FilledButton(
                        onPressed: () =>
                            open(PartRequestScreen(orderId: widget.orderId)),
                        child: const Text('Minta sparepart ke admin'),
                      ),
                    if (role != 'customer')
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tampilkan permintaan'),
                        value: requests,
                        onChanged: (v) => setState(() {
                          requests = v;
                          cursors
                            ..clear()
                            ..add(null);
                        }),
                      ),
                    if (!requests || role == 'customer')
                      const Text(
                        'Pemakaian dan reversal ditampilkan terpisah. Reversal mengembalikan seluruh qty baris asal.',
                      ),
                    ref
                        .watch(provider)
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, _) => RetryLoad(
                            onRetry: () => ref.invalidate(provider),
                          ),
                          data: (page) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (page.items.isEmpty)
                                Text(
                                  requests
                                      ? 'Belum ada permintaan.'
                                      : 'Belum ada pemakaian sparepart.',
                                ),
                              for (final row in page.items)
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${row['sku']} • qty ${row['quantity']}',
                                        ),
                                        if (requests) ...[
                                          Text('Status: ${row['status']}'),
                                          Text('Alasan: ${row['reason']}'),
                                          if (row['decisionReason'] != '')
                                            Text(
                                              'Keputusan: ${row['decisionReason']}',
                                            ),
                                          if (role == 'admin' &&
                                              row['status'] == 'pending')
                                            for (final approve in [true, false])
                                              OutlinedButton(
                                                onPressed:
                                                    approve &&
                                                        order.status.terminal
                                                    ? null
                                                    : () => open(
                                                        InventoryReasonScreen(
                                                          title: approve
                                                              ? 'Setujui pemakaian'
                                                              : 'Tolak permintaan',
                                                          onSubmit: (reason) => ref
                                                              .read(
                                                                inventoryRepositoryProvider,
                                                              )
                                                              .decideRequest(
                                                                widget.orderId,
                                                                row['id']
                                                                    as String,
                                                                approve:
                                                                    approve,
                                                                reason: reason,
                                                              ),
                                                        ),
                                                      ),
                                                child: Text(
                                                  approve
                                                      ? 'Setujui dan kurangi stok'
                                                      : 'Tolak',
                                                ),
                                              ),
                                        ] else ...[
                                          Text(
                                            '${row['name']} • ${row['kind'] == 'reversal' ? 'Dikembalikan' : 'Dipakai'}',
                                          ),
                                          Text(
                                            'Harga snapshot: Rp ${row['sellPrice']} / ${row['unit']}',
                                          ),
                                          if (row['reversalOf'] != null)
                                            Text(
                                              'Reversal dari ${row['reversalOf']}',
                                            ),
                                          if (role == 'admin' &&
                                              row['kind'] == 'usage')
                                            OutlinedButton(
                                              onPressed: () => open(
                                                InventoryReasonScreen(
                                                  title:
                                                      'Reversal penuh ${row['sku']}',
                                                  onSubmit: (reason) => ref
                                                      .read(
                                                        inventoryRepositoryProvider,
                                                      )
                                                      .reverse(
                                                        row['movementId']
                                                            as String,
                                                        reason,
                                                      ),
                                                ),
                                              ),
                                              child: const Text(
                                                'Reversal pemakaian',
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              PageButtons(
                                page: cursors.length,
                                hasMore: page.hasMore,
                                previous: () =>
                                    setState(() => cursors.removeLast()),
                                next: () =>
                                    setState(() => cursors.add(page.cursor)),
                              ),
                            ],
                          ),
                        ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class PartRequestScreen extends ConsumerStatefulWidget {
  const PartRequestScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<PartRequestScreen> createState() => _PartRequestState();
}

class _PartRequestState extends ConsumerState<PartRequestScreen> {
  final form = GlobalKey<FormState>();
  final sku = TextEditingController(),
      qty = TextEditingController(),
      reason = TextEditingController();
  String? id, error;
  bool busy = false;
  @override
  void dispose() {
    sku.dispose();
    qty.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Permintaan sparepart')),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Masukkan SKU dari label sparepart. Admin memeriksa ketersediaan dan menyetujui pemakaian.',
            ),
            TextFormField(
              controller: sku,
              enabled: !busy && id == null,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (v) =>
                  validSku(canonicalSku(v ?? '')) ? null : 'SKU tidak valid.',
            ),
            TextFormField(
              controller: qty,
              enabled: !busy && id == null,
              decoration: const InputDecoration(labelText: 'Qty'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 || n > maxQuantity
                    ? 'Qty harus 1–$maxQuantity.'
                    : null;
              },
            ),
            TextFormField(
              controller: reason,
              enabled: !busy && id == null,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Alasan permintaan'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alasan wajib.' : null,
            ),
            if (error != null) Text(error!),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (busy || !form.currentState!.validate()) return;
                      final repo = ref.read(inventoryRepositoryProvider);
                      id ??= repo.newOperationId();
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await repo.requestPart(
                          id!,
                          widget.orderId,
                          sku.text,
                          int.parse(qty.text),
                          reason.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            busy = false;
                            error = 'Permintaan belum dikonfirmasi: $e';
                          });
                        }
                      }
                    },
              child: Text(
                busy
                    ? 'Mengirim…'
                    : id == null
                    ? 'Kirim permintaan'
                    : 'Coba lagi permintaan yang sama',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
