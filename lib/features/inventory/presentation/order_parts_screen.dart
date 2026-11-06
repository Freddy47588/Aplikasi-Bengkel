import '../../../core/widgets/workshop_ui.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/user_role.dart';
import '../../technician/presentation/technician_form_ui.dart';
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
      body: WorkshopBody(
        child: ref
            .watch(serviceOrderProvider(widget.orderId))
            .when(
              loading: () => const LoadingState(),
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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
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
                          loading: () => const LoadingState(),
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
      qty = TextEditingController(text: '1'),
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
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Permintaan Sparepart'),
      ),
      body: WorkshopBody(
        showWave: true,
        child: ref
            .watch(serviceOrderProvider(widget.orderId))
            .when(
              loading: () => const LoadingState(),
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
                if (session.role != UserRole.technician ||
                    order.technicianId != session.userId) {
                  return const Center(
                    child: Text(
                      'Permintaan hanya untuk tugas teknisi yang bersangkutan.',
                    ),
                  );
                }
                final available = [
                  'inProgress',
                  'paused',
                ].contains(order.status.name);
                final editable = !busy && id == null && available;
                final amount = int.tryParse(qty.text);
                final validAmount =
                    amount != null && amount >= 1 && amount <= maxQuantity;
                return Form(
                  key: form,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      const TechnicianFormIntro(
                        art: WorkshopArt.spareparts,
                        description:
                            'Ajukan sparepart yang dibutuhkan untuk pekerjaan servis.',
                      ),
                      TaskVehicleCard(
                        order: order,
                        onTap: Navigator.canPop(context)
                            ? () => Navigator.pop(context)
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Daftar Sparepart',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajukan satu SKU per permintaan. Gunakan kode pada label sparepart.',
                      ),
                      const SizedBox(height: 12),
                      if (!available)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Permintaan baru tersedia setelah tugas dimulai.',
                          ),
                        ),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.blueBorder),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 14),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.secondary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: sku,
                                      enabled: editable,
                                      maxLength: 40,
                                      decoration: const InputDecoration(
                                        labelText: 'SKU',
                                      ),
                                      validator: (v) =>
                                          validSku(canonicalSku(v ?? ''))
                                          ? null
                                          : 'SKU tidak valid.',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton.outlined(
                                    tooltip: 'Kurangi jumlah',
                                    onPressed:
                                        editable && validAmount && amount > 1
                                        ? () => setState(
                                            () => qty.text = '${amount - 1}',
                                          )
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 120,
                                      ),
                                      child: TextFormField(
                                        controller: qty,
                                        enabled: editable,
                                        textAlign: TextAlign.center,
                                        onChanged: (_) => setState(() {}),
                                        decoration: const InputDecoration(
                                          labelText: 'Qty',
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (v) {
                                          final n = int.tryParse(v ?? '');
                                          return n == null ||
                                                  n <= 0 ||
                                                  n > maxQuantity
                                              ? 'Qty harus 1–$maxQuantity.'
                                              : null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.outlined(
                                    tooltip: 'Tambah jumlah',
                                    onPressed:
                                        editable &&
                                            validAmount &&
                                            amount < maxQuantity
                                        ? () => setState(
                                            () => qty.text = '${amount + 1}',
                                          )
                                        : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: reason,
                        enabled: editable,
                        minLines: 2,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Alasan permintaan',
                          helperText: 'Wajib untuk persetujuan admin.',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Alasan wajib.'
                            : null,
                      ),
                      if (error != null) Text(error!),
                      FilledButton.icon(
                        icon: const Icon(Icons.send_outlined),
                        onPressed: busy || (!available && id == null)
                            ? null
                            : () async {
                                if (busy || !form.currentState!.validate()) {
                                  return;
                                }
                                final repo = ref.read(
                                  inventoryRepositoryProvider,
                                );
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
                                  if (context.mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setState(() {
                                      busy = false;
                                      error =
                                          'Permintaan belum dikonfirmasi: $e';
                                    });
                                  }
                                }
                              },
                        label: Text(
                          busy
                              ? 'Mengirim…'
                              : id == null
                              ? 'Ajukan Sparepart'
                              : 'Coba lagi permintaan yang sama',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}
