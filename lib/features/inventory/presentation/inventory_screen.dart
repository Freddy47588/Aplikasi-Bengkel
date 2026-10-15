import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/data/inventory_repository.dart';
import '../../../core/models/inventory.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../technician/presentation/service_orders_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key, this.orderId});
  final String? orderId;
  @override
  ConsumerState<InventoryScreen> createState() => _InventoryState();
}

class _InventoryState extends ConsumerState<InventoryScreen> {
  final search = TextEditingController(), category = TextEditingController();
  String prefix = '', appliedCategory = '';
  bool? active = true;
  bool low = false;
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  void dispose() {
    search.dispose();
    category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(authSessionProvider).isAuthenticated) {
      return const SizedBox.shrink();
    }
    final filter = (
      cursor: cursors.last,
      search: prefix,
      category: appliedCategory,
      active: active,
      lowOnly: low,
    );
    final provider = inventoryPageProvider(filter);
    Future<void> open(Widget screen) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      if (mounted) ref.invalidate(provider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.orderId == null ? 'Inventori sparepart' : 'Pilih sparepart SO',
        ),
        leading: widget.orderId == null
            ? IconButton(
                onPressed: () => context.go('/admin/home'),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
          ),
          if (widget.orderId == null)
            IconButton(
              tooltip: 'Tambah sparepart',
              onPressed: () => open(const SparepartEditor()),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      bottomNavigationBar: widget.orderId == null
          ? const MobileNavigation(role: 'admin')
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.orderId == null)
              OutlinedButton(
                onPressed: () => open(const StockLedgerScreen()),
                child: const Text('Ledger stok'),
              ),
            TextField(
              controller: search,
              decoration: const InputDecoration(labelText: 'Cari awalan SKU'),
            ),
            TextField(
              controller: category,
              decoration: const InputDecoration(
                labelText: 'Kategori persis (kosong = semua)',
              ),
            ),
            DropdownButtonFormField<bool?>(
              initialValue: active,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('Semua')),
                DropdownMenuItem(value: true, child: Text('Aktif')),
                DropdownMenuItem(value: false, child: Text('Nonaktif')),
              ],
              onChanged: (v) => setState(() {
                active = v;
                cursors
                  ..clear()
                  ..add(null);
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Stok minimum / habis'),
              value: low,
              onChanged: (v) => setState(() {
                low = v;
                cursors
                  ..clear()
                  ..add(null);
              }),
            ),
            TextButton(
              onPressed: () => setState(() {
                prefix = search.text.trim();
                appliedCategory = category.text.trim();
                cursors
                  ..clear()
                  ..add(null);
              }),
              child: const Text('Terapkan pencarian'),
            ),
            ref
                .watch(provider)
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      RetryLoad(onRetry: () => ref.invalidate(provider)),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.items.isEmpty)
                        const Text('Tidak ada sparepart sesuai filter.'),
                      for (final p in page.items)
                        Card(
                          child: ListTile(
                            title: Text('${p.id} • ${p.text('name')}'),
                            subtitle: Text(
                              'Stok ${p.stock} ${p.text('unit')} • min. ${p.number('minimumStock')}\nRp ${p.number('sellPrice')}${p.lowStock ? ' • Stok rendah' : ''}',
                            ),
                            onTap: () => open(
                              SparepartDetailScreen(
                                sku: p.id,
                                orderId: widget.orderId,
                              ),
                            ),
                          ),
                        ),
                      PageButtons(
                        page: cursors.length,
                        hasMore: page.hasMore,
                        previous: () => setState(() => cursors.removeLast()),
                        next: () => setState(() => cursors.add(page.cursor)),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class SparepartEditor extends ConsumerStatefulWidget {
  const SparepartEditor({super.key, this.part});
  final Sparepart? part;
  @override
  ConsumerState<SparepartEditor> createState() => _SparepartEditorState();
}

class _SparepartEditorState extends ConsumerState<SparepartEditor> {
  final form = GlobalKey<FormState>();
  late final fields = {
    for (final key in [
      'sku',
      'name',
      'category',
      'unit',
      'supplier',
      'buyPrice',
      'sellPrice',
      'minimumStock',
    ])
      key: TextEditingController(
        text:
            '${widget.part?.data[key] ?? (['buyPrice', 'sellPrice', 'minimumStock'].contains(key) ? 0 : '')}',
      ),
  };
  late bool active = widget.part?.active ?? true;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.part == null ? 'Tambah sparepart' : 'Edit sparepart'),
    ),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final (key, label, max) in [
              ('sku', 'SKU unik', 40),
              ('name', 'Nama', 100),
              ('category', 'Kategori', 60),
              ('unit', 'Satuan', 20),
              ('supplier', 'Supplier (opsional)', 160),
              ('buyPrice', 'Harga beli (rupiah)', 10),
              ('sellPrice', 'Harga jual (rupiah)', 10),
              ('minimumStock', 'Stok minimum', 10),
            ])
              TextFormField(
                controller: fields[key],
                enabled: !busy && (key != 'sku' || widget.part == null),
                maxLength: max,
                decoration: InputDecoration(labelText: label),
                keyboardType:
                    ['buyPrice', 'sellPrice', 'minimumStock'].contains(key)
                    ? TextInputType.number
                    : TextInputType.text,
                validator: (value) {
                  if (key == 'supplier') return null;
                  if (['buyPrice', 'sellPrice', 'minimumStock'].contains(key)) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 0 || n > maxRupiah
                        ? 'Isi integer 0–$maxRupiah.'
                        : null;
                  }
                  if (key == 'sku') {
                    return validSku(canonicalSku(value ?? ''))
                        ? null
                        : 'SKU: huruf/angka, - atau _, maksimal 40.';
                  }
                  return value == null || value.trim().isEmpty
                      ? 'Wajib diisi.'
                      : null;
                },
              ),
            SwitchListTile(
              title: const Text('Aktif'),
              subtitle: const Text(
                'Nonaktif mengarsipkan SKU; ledger tetap disimpan.',
              ),
              value: active,
              onChanged: busy ? null : (v) => setState(() => active = v),
            ),
            if (error != null) Text(error!),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (busy || !form.currentState!.validate()) return;
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await ref
                            .read(inventoryRepositoryProvider)
                            .save(
                              SparepartDraft(
                                sku: fields['sku']!.text,
                                name: fields['name']!.text,
                                category: fields['category']!.text,
                                unit: fields['unit']!.text,
                                supplier: fields['supplier']!.text,
                                buyPrice: int.parse(fields['buyPrice']!.text),
                                sellPrice: int.parse(fields['sellPrice']!.text),
                                minimumStock: int.parse(
                                  fields['minimumStock']!.text,
                                ),
                                active: active,
                              ),
                              expectedVersion: widget.part?.version,
                            );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            busy = false;
                            error = 'Gagal menyimpan: $e';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Menyimpan…' : 'Simpan master'),
            ),
          ],
        ),
      ),
    ),
  );
}

class SparepartDetailScreen extends ConsumerWidget {
  const SparepartDetailScreen({super.key, required this.sku, this.orderId});
  final String sku;
  final String? orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> open(Widget screen) async {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      if (context.mounted) ref.invalidate(sparepartProvider(sku));
    }

    return Scaffold(
      appBar: AppBar(title: Text(sku)),
      body: SafeArea(
        child: ref
            .watch(sparepartProvider(sku))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => RetryLoad(
                onRetry: () => ref.invalidate(sparepartProvider(sku)),
              ),
              data: (p) => p == null
                  ? const Center(child: Text('Sparepart tidak ditemukan.'))
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          p.text('name'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text('${p.text('category')} • ${p.text('unit')}'),
                        Text(
                          'Stok: ${p.stock} • minimum ${p.number('minimumStock')}',
                        ),
                        Text(
                          'Beli Rp ${p.number('buyPrice')} • jual Rp ${p.number('sellPrice')}',
                        ),
                        Text('Supplier: ${p.text('supplier')}'),
                        Text(p.active ? 'Aktif' : 'Nonaktif'),
                        if (p.lowStock) const Text('Stok minimum / habis'),
                        OutlinedButton(
                          onPressed: () => open(SparepartEditor(part: p)),
                          child: const Text('Edit / arsipkan master'),
                        ),
                        FilledButton(
                          onPressed: p.active
                              ? () => open(
                                  StockOperationScreen(
                                    sku: sku,
                                    orderId: orderId,
                                  ),
                                )
                              : null,
                          child: Text(
                            orderId == null
                                ? 'Catat transaksi stok'
                                : 'Catat pemakaian SO',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => open(StockLedgerScreen(sku: sku)),
                          child: const Text('Ledger SKU'),
                        ),
                      ],
                    ),
            ),
      ),
    );
  }
}

class StockOperationScreen extends ConsumerStatefulWidget {
  const StockOperationScreen({super.key, required this.sku, this.orderId});
  final String sku;
  final String? orderId;
  @override
  ConsumerState<StockOperationScreen> createState() => _StockOperationState();
}

class _StockOperationState extends ConsumerState<StockOperationScreen> {
  final form = GlobalKey<FormState>();
  final qty = TextEditingController(), reason = TextEditingController();
  late final so = TextEditingController(text: widget.orderId);
  late MovementKind kind = widget.orderId == null
      ? MovementKind.receipt
      : MovementKind.usage;
  bool decrease = false, busy = false;
  MovementCommand? submitted;
  String? error;
  @override
  void dispose() {
    qty.dispose();
    reason.dispose();
    so.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Transaksi ${widget.sku}')),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<MovementKind>(
              initialValue: kind,
              items: [
                for (final k in MovementKind.values.where(
                  (k) =>
                      k != MovementKind.reversal &&
                      (widget.orderId == null || k == MovementKind.usage),
                ))
                  DropdownMenuItem(value: k, child: Text(k.label)),
              ],
              onChanged: busy || submitted != null
                  ? null
                  : (v) => setState(() => kind = v!),
            ),
            if (kind == MovementKind.adjustment)
              SwitchListTile(
                title: const Text('Koreksi mengurangi stok'),
                value: decrease,
                onChanged: busy || submitted != null
                    ? null
                    : (v) => setState(() => decrease = v),
              ),
            if (kind == MovementKind.usage)
              TextFormField(
                controller: so,
                enabled: !busy && submitted == null && widget.orderId == null,
                decoration: const InputDecoration(
                  labelText: 'ID Service Order',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty || v.contains('/')
                    ? 'ID Service Order wajib.'
                    : null,
              ),
            TextFormField(
              controller: qty,
              enabled: !busy && submitted == null,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Qty integer positif',
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 || n > maxQuantity
                    ? 'Qty harus 1–$maxQuantity.'
                    : null;
              },
            ),
            TextFormField(
              controller: reason,
              enabled: !busy && submitted == null,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Alasan transaksi'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alasan wajib.' : null,
            ),
            if (error != null) Text(error!),
            if (submitted != null && !busy)
              const Text(
                'Coba lagi memeriksa operasi yang sama. Kembali untuk memulai transaksi berbeda; periksa ledger dahulu bila hasil belum pasti.',
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (busy || !form.currentState!.validate()) return;
                      final repo = ref.read(inventoryRepositoryProvider);
                      submitted ??= MovementCommand(
                        id: repo.newOperationId(),
                        sku: widget.sku,
                        kind: kind,
                        quantity: int.parse(qty.text),
                        reason: reason.text,
                        decrease: decrease,
                        serviceOrderId: kind == MovementKind.usage
                            ? so.text.trim()
                            : null,
                      );
                      setState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await repo.post(submitted!);
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            busy = false;
                            error = 'Transaksi belum dikonfirmasi: $e';
                          });
                        }
                      }
                    },
              child: Text(
                busy
                    ? 'Memproses…'
                    : submitted == null
                    ? 'Catat transaksi'
                    : 'Coba lagi operasi yang sama',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class StockLedgerScreen extends ConsumerStatefulWidget {
  const StockLedgerScreen({super.key, this.sku = '', this.orderId = ''});
  final String sku, orderId;
  @override
  ConsumerState<StockLedgerScreen> createState() => _StockLedgerState();
}

class _StockLedgerState extends ConsumerState<StockLedgerScreen> {
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  Widget build(BuildContext context) {
    final provider = ledgerPageProvider((
      cursor: cursors.last,
      sku: widget.sku,
      serviceOrderId: widget.orderId,
    ));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger stok'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  RetryLoad(onRetry: () => ref.invalidate(provider)),
              data: (page) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (page.items.isEmpty)
                    const Text('Belum ada movement di halaman ini.'),
                  for (final m in page.items)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.sku} • ${m.kind.label} • ${m.delta > 0 ? '+' : ''}${m.delta}',
                            ),
                            Text(
                              '${m.data['balanceBefore']} → ${m.data['balanceAfter']}',
                            ),
                            Text('Alasan: ${m.data['reason']}'),
                            Text('Actor: ${m.data['actorId']}'),
                            Text(
                              'Waktu: ${(m.data['createdAt'] as Timestamp?)?.toDate().toLocal()}',
                            ),
                            if (m.data['serviceOrderId'] != null)
                              Text('SO: ${m.data['serviceOrderId']}'),
                            if (m.data['reversalOf'] != null)
                              Text('Reversal: ${m.data['reversalOf']}'),
                            if (m.kind != MovementKind.reversal)
                              TextButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InventoryReasonScreen(
                                        title: 'Reversal penuh ${m.sku}',
                                        onSubmit: (reason) => ref
                                            .read(inventoryRepositoryProvider)
                                            .reverse(m.id, reason),
                                      ),
                                    ),
                                  );
                                  if (mounted) ref.invalidate(provider);
                                },
                                child: const Text('Reversal penuh'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  PageButtons(
                    page: cursors.length,
                    hasMore: page.hasMore,
                    previous: () => setState(() => cursors.removeLast()),
                    next: () => setState(() => cursors.add(page.cursor)),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class InventoryReasonScreen extends StatefulWidget {
  const InventoryReasonScreen({
    super.key,
    required this.title,
    required this.onSubmit,
  });
  final String title;
  final Future<Object?> Function(String reason) onSubmit;
  @override
  State<InventoryReasonScreen> createState() => _ReasonState();
}

class _ReasonState extends State<InventoryReasonScreen> {
  final reason = TextEditingController();
  bool busy = false, locked = false;
  String? error;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: reason,
            enabled: !busy && !locked,
            minLines: 2,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Alasan keputusan'),
          ),
          if (error != null) Text(error!),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (busy) return;
                    if (reason.text.trim().isEmpty) {
                      setState(() => error = 'Alasan wajib.');
                      return;
                    }
                    setState(() {
                      busy = true;
                      locked = true;
                      error = null;
                    });
                    try {
                      await widget.onSubmit(reason.text);
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          busy = false;
                          error = 'Belum dikonfirmasi: $e';
                        });
                      }
                    }
                  },
            child: Text(
              busy
                  ? 'Memproses…'
                  : locked
                  ? 'Coba lagi keputusan yang sama'
                  : 'Konfirmasi',
            ),
          ),
        ],
      ),
    ),
  );
}
