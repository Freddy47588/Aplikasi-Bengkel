import '../../../core/widgets/workshop_ui.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/user_role.dart';
import 'inventory_ui.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../core/data/inventory_repository.dart';
import '../../../core/models/inventory.dart';
import '../../../core/models/service_history.dart';
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
  bool low = false, showFilters = false;
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  void dispose() {
    search.dispose();
    category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) {
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

    void applySearch() => setState(() {
      prefix = search.text.trim();
      appliedCategory = category.text.trim();
      cursors
        ..clear()
        ..add(null);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.orderId == null ? 'Inventori Sparepart' : 'Pilih sparepart SO',
        ),
        leading: widget.orderId == null
            ? IconButton(
                onPressed: () => context.go('/admin/home'),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu inventori',
            onSelected: (value) {
              if (value == 'refresh') ref.invalidate(provider);
              if (value == 'ledger') open(const StockLedgerScreen());
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'refresh', child: Text('Muat ulang')),
              if (widget.orderId == null)
                const PopupMenuItem(
                  value: 'ledger',
                  child: Text('Riwayat Stok'),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: widget.orderId == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (session.role == UserRole.admin)
                  SafeArea(
                    top: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: Tooltip(
                          message: 'Tambah sparepart',
                          child: FilledButton.icon(
                            onPressed: () => open(const SparepartEditor()),
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Sparepart'),
                          ),
                        ),
                      ),
                    ),
                  ),
                const MobileNavigation(role: 'admin'),
              ],
            )
          : null,
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const InventoryIntro(
              art: WorkshopArt.spareparts,
              description:
                  'Kelola daftar sparepart, pantau stok, dan jaga ketersediaan untuk kebutuhan servis.',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => applySearch(),
                    decoration: InputDecoration(
                      labelText: 'Cari SKU sparepart',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Terapkan pencarian',
                        onPressed: applySearch,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  width: 52,
                  child: IconButton.outlined(
                    tooltip: 'Filter inventori',
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    isSelected: showFilters,
                    onPressed: () => setState(() => showFilters = !showFilters),
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            if (showFilters) ...[
              const SizedBox(height: 12),
              const Text(
                'Pencarian memakai awalan SKU. Kategori harus sama persis.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  helperText:
                      'Gunakan kategori pada detail sparepart; kosongkan untuk semua.',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool?>(
                isExpanded: true,
                itemHeight: null,
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
                onPressed: applySearch,
                child: const Text('Terapkan pencarian'),
              ),
            ],
            const SizedBox(height: 12),
            ref
                .watch(provider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) =>
                      RetryLoad(onRetry: () => ref.invalidate(provider)),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.items.isEmpty)
                        const EmptyState(
                          title: 'Sparepart belum ditemukan',
                          description: 'Tidak ada sparepart sesuai filter.',
                          icon: Icons.inventory_2_outlined,
                        ),
                      for (final p in page.items)
                        InventoryPartCard(
                          part: p,
                          onTap: () => open(
                            SparepartDetailScreen(
                              sku: p.id,
                              orderId: widget.orderId,
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
    body: WorkshopBody(
      child: Form(
        key: form,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      if (widget.part?.active == true && !active) {
                        setState(() => busy = true);
                        final approved = await confirmWorkshopAction(
                          context,
                          'Arsipkan sparepart ini? Transaksi stok baru dinonaktifkan; ledger dan riwayat tetap tersimpan.',
                          title: 'Arsipkan sparepart?',
                          confirmLabel: 'Arsipkan',
                        );
                        if (!mounted) return;
                        if (!approved) {
                          setState(() => busy = false);
                          return;
                        }
                      }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Stok'),
      ),
      body: WorkshopBody(
        showWave: true,
        child: ref
            .watch(sparepartProvider(sku))
            .when(
              loading: () => const LoadingState(),
              error: (_, _) => RetryLoad(
                onRetry: () => ref.invalidate(sparepartProvider(sku)),
              ),
              data: (p) => p == null
                  ? const Center(child: Text('Sparepart tidak ditemukan.'))
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        WorkshopIllustration(
                          p.text('name').toLowerCase().contains('oli')
                              ? WorkshopArt.oil
                              : WorkshopArt.spareparts,
                          height: 156,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.text('name'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Chip(
                            backgroundColor: AppColors.blueSurface,
                            side: BorderSide.none,
                            avatar: const Icon(
                              Icons.qr_code,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            label: Text(
                              p.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (!p.active) Center(child: StockBadge(part: p)),
                        const SizedBox(height: 20),
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.blueBorder),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Column(
                              children: [
                                StockInfoRow(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Kategori',
                                  value: p.text('category'),
                                ),
                                const Divider(height: 1),
                                StockInfoRow(
                                  icon: Icons.layers_outlined,
                                  label: 'Stok Tersedia',
                                  value: '',
                                  badge: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${p.stock} ${p.text('unit')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      StockBadge(part: p),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                StockInfoRow(
                                  icon: Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                  label: 'Stok Minimum',
                                  value:
                                      '${p.number('minimumStock')} ${p.text('unit')}',
                                ),
                                const Divider(height: 1),
                                StockInfoRow(
                                  icon: Icons.sell_outlined,
                                  label: 'Harga jual',
                                  value: rupiah(p.number('sellPrice')),
                                ),
                                const Divider(height: 1),
                                StockInfoRow(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Harga beli',
                                  value: rupiah(p.number('buyPrice')),
                                ),
                                if (p.text('supplier').isNotEmpty) ...[
                                  const Divider(height: 1),
                                  StockInfoRow(
                                    icon: Icons.local_shipping_outlined,
                                    label: 'Supplier',
                                    value: p.text('supplier'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (ref.watch(authSessionProvider).role ==
                            UserRole.admin) ...[
                          LayoutBuilder(
                            builder: (context, box) {
                              final incoming = FilledButton.icon(
                                onPressed: p.active && orderId == null
                                    ? () => open(
                                        StockOperationScreen(
                                          sku: sku,
                                          initialKind: MovementKind.receipt,
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.move_to_inbox_outlined),
                                label: const Text('Stok Masuk'),
                              );
                              final outgoing = OutlinedButton.icon(
                                onPressed: p.active
                                    ? () => open(
                                        StockOperationScreen(
                                          sku: sku,
                                          orderId: orderId,
                                          initialKind: MovementKind.usage,
                                        ),
                                      )
                                    : null,
                                icon: const Icon(Icons.outbox_outlined),
                                label: const Text('Stok Keluar'),
                              );
                              if (box.maxWidth < 340 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    incoming,
                                    const SizedBox(height: 10),
                                    outgoing,
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(child: incoming),
                                  const SizedBox(width: 12),
                                  Expanded(child: outgoing),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: p.active
                                ? () => open(
                                    StockOperationScreen(
                                      sku: sku,
                                      orderId: orderId,
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.tune),
                            label: Text(
                              orderId == null
                                  ? 'Catat transaksi stok / koreksi'
                                  : 'Catat pemakaian SO',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => open(SparepartEditor(part: p)),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit / arsipkan master'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => open(StockLedgerScreen(sku: sku)),
                          child: const Text('Riwayat pergerakan stok'),
                        ),
                      ],
                    ),
            ),
      ),
    );
  }
}

class StockOperationScreen extends ConsumerStatefulWidget {
  const StockOperationScreen({
    super.key,
    required this.sku,
    this.orderId,
    this.initialKind = MovementKind.receipt,
  }) : assert(initialKind != MovementKind.reversal);
  final String sku;
  final String? orderId;
  final MovementKind initialKind;
  @override
  ConsumerState<StockOperationScreen> createState() => _StockOperationState();
}

class _StockOperationState extends ConsumerState<StockOperationScreen> {
  final form = GlobalKey<FormState>();
  final qty = TextEditingController(), reason = TextEditingController();
  late final so = TextEditingController(text: widget.orderId);
  late MovementKind kind = widget.orderId == null
      ? widget.initialKind
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
    body: WorkshopBody(
      child: Form(
        key: form,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<MovementKind>(
              isExpanded: true,
              itemHeight: null,
              decoration: const InputDecoration(labelText: 'Jenis transaksi'),
              initialValue: kind,
              items: [
                for (final k in MovementKind.values.where(
                  (k) =>
                      k != MovementKind.reversal &&
                      (widget.orderId == null || k == MovementKind.usage),
                ))
                  DropdownMenuItem(
                    value: k,
                    child: Row(
                      children: [
                        Icon(switch (k) {
                          MovementKind.receipt => Icons.move_to_inbox_outlined,
                          MovementKind.usage => Icons.outbox_outlined,
                          MovementKind.adjustment => Icons.tune,
                          MovementKind.reversal => Icons.undo,
                        }),
                        const SizedBox(width: 12),
                        Expanded(child: Text(k.label)),
                      ],
                    ),
                  ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: qty,
              enabled: !busy && submitted == null,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah unit'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n <= 0 || n > maxQuantity
                    ? 'Qty harus 1–$maxQuantity.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
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
  late final search = TextEditingController(text: widget.sku);
  late final order = TextEditingController(text: widget.orderId);
  late String appliedSku = widget.sku, appliedOrder = widget.orderId;
  bool showFilters = false;

  @override
  void dispose() {
    search.dispose();
    order.dispose();
    super.dispose();
  }

  void applyFilters() => setState(() {
    appliedSku = widget.sku.isEmpty ? canonicalSku(search.text) : widget.sku;
    appliedOrder = widget.orderId.isEmpty ? order.text.trim() : widget.orderId;
    cursors
      ..clear()
      ..add(null);
  });

  @override
  Widget build(BuildContext context) {
    final provider = ledgerPageProvider((
      cursor: cursors.last,
      sku: appliedSku,
      serviceOrderId: appliedOrder,
    ));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Riwayat Stok'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const InventoryIntro(
              art: WorkshopArt.ledger,
              description:
                  'Riwayat pergerakan stok sparepart (masuk, keluar, dan koreksi).',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    enabled: widget.sku.isEmpty,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => applyFilters(),
                    decoration: InputDecoration(
                      labelText: 'Cari riwayat: SKU',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Cari riwayat stok',
                        onPressed: applyFilters,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  width: 52,
                  child: IconButton.outlined(
                    tooltip: 'Filter riwayat stok',
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    isSelected: showFilters,
                    onPressed: () => setState(() => showFilters = !showFilters),
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            if (showFilters) ...[
              const SizedBox(height: 12),
              const Text(
                'Gunakan SKU lengkap. Filter tetap mencakup seluruh halaman ledger.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: order,
                enabled: widget.orderId.isEmpty,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => applyFilters(),
                decoration: const InputDecoration(
                  labelText: 'ID Service Order',
                ),
              ),
              TextButton(
                onPressed: applyFilters,
                child: const Text('Terapkan filter riwayat'),
              ),
            ],
            const SizedBox(height: 12),
            ref
                .watch(provider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) =>
                      RetryLoad(onRetry: () => ref.invalidate(provider)),
                  data: (page) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (page.items.isEmpty)
                        const EmptyState(
                          title: 'Belum ada riwayat stok',
                          description:
                              'Tidak ada transaksi sesuai filter di halaman ini.',
                          icon: Icons.history,
                        ),
                      for (final m in page.items)
                        StockMovementCard(
                          movement: m,
                          onReverse:
                              m.kind == MovementKind.reversal ||
                                  ref.watch(authSessionProvider).role !=
                                      UserRole.admin
                              ? null
                              : () async {
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
    body: WorkshopBody(
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
