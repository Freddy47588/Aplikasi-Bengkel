import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/data/payment_repository.dart';
import '../../../core/data/invoice_pdf.dart';
import '../../../core/data/report_repository.dart';
import '../../../core/models/invoice.dart';
import '../../../core/models/service_history.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/dashboard_stat_card.dart';
import '../../../app/theme/app_colors.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, this.orderId = ''});
  final String orderId;
  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsState();
}

class _PaymentsState extends ConsumerState<PaymentsScreen> {
  late DateTime from, until;
  DocumentSnapshot<Map<String, dynamic>>? cursor;
  final order = TextEditingController(),
      discount = TextEditingController(text: '0'),
      fee = TextEditingController(text: '0'),
      notes = TextEditingController();
  bool busy = false;
  String? error;
  WorkshopReport? report;
  @override
  void initState() {
    super.initState();
    order.text = widget.orderId;
    final today = DateTime.now().toUtc().add(const Duration(hours: 7));
    until = wibDay(DateTime(today.year, today.month, today.day + 1));
    from = until.subtract(const Duration(days: 7));
  }

  @override
  void dispose() {
    for (final c in [order, discount, fee, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authSessionProvider).role == UserRole.admin;
    final filter = (from: from, until: until, cursor: cursor);
    final page = ref.watch(invoicePageProvider(filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran & transaksi')),
      bottomNavigationBar: MobileNavigation(role: admin ? 'admin' : 'customer'),
      body: WorkshopBody(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          children: [
            const PageIntro(
              showTitle: false,
              art: WorkshopArt.checklist,
              title: 'Invoice servis',
              description:
                  'Lihat tagihan dan status pembayaran pada periode yang dipilih.',
            ),
            Text(
              'Periode terbit: ${historyDate(from)} sampai ${historyDate(until)} (akhir eksklusif)',
            ),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (range != null && mounted) {
                        setState(() {
                          from = wibDay(range.start);
                          until = wibDay(
                            range.end.add(const Duration(days: 1)),
                          );
                          cursor = null;
                          report = null;
                        });
                      }
                    },
              child: const Text('Filter tanggal WIB'),
            ),
            if (admin) ...[
              ExpansionTile(
                initiallyExpanded: widget.orderId.isNotEmpty,
                title: const Text('Terbitkan invoice SO selesai'),
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: order,
                    readOnly: widget.orderId.isNotEmpty,
                    decoration: const InputDecoration(
                      labelText: 'Referensi Service Order',
                      helperText:
                          'Buka dari detail servis selesai untuk mengisi otomatis.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diskon rupiah (otorisasi admin)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fee,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Biaya tambahan rupiah (otorisasi admin)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Alasan/otorisasi diskon dan biaya',
                    ),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => run(() async {
                            if (!await confirmAction(
                              context,
                              'Terbitkan invoice dengan harga final dan penyesuaian ini?',
                            )) {
                              return;
                            }
                            await ref
                                .read(paymentRepositoryProvider)
                                .create(
                                  order.text.trim(),
                                  discount: int.parse(discount.text),
                                  fee: int.parse(fee.text),
                                  reason: notes.text,
                                );
                            ref.invalidate(invoicePageProvider);
                            if (context.mounted) {
                              context.push(
                                '/admin/invoices/${order.text.trim()}',
                              );
                            }
                          }),
                    child: const Text('Terbitkan invoice'),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final result = await ref
                            .read(reportRepositoryProvider)
                            .load(from, until);
                        if (mounted) setState(() => report = result);
                      }),
                child: const Text('Muat laporan (maks. 31 hari)'),
              ),
              const Text(
                'Laporan memakai periode yang dipilih. Omzet: total invoice lunas menurut tanggal pelunasan; bukan laba. Refund penuh dikeluarkan dari omzet. Stok menipis adalah kondisi saat ini.',
              ),
              if (report case final r?)
                ContentSection(
                  title: 'Laporan periode terpilih',
                  children: [
                    const WorkshopIllustration(WorkshopArt.report),
                    AdaptiveCards(
                      children: [
                        DashboardStatCard(
                          label: 'Booking',
                          value: '${r.bookings}',
                          icon: Icons.event_note,
                          color: AppColors.primary,
                        ),
                        DashboardStatCard(
                          label: 'SO selesai',
                          value: '${r.completed}',
                          icon: Icons.task_alt,
                          color: AppColors.success,
                        ),
                        DashboardStatCard(
                          label: 'Omzet lunas',
                          value: rupiah(r.revenue),
                          icon: Icons.receipt_long,
                          color: AppColors.warning,
                        ),
                        DashboardStatCard(
                          label: 'Pemakaian part net (unit)',
                          value: '${r.partUnits}',
                          icon: Icons.build_outlined,
                          color: AppColors.primary,
                        ),
                        DashboardStatCard(
                          label: 'Stok menipis (SKU)',
                          value: '${r.lowStock}',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.danger,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            page.when(
              loading: () => const LoadingState(),
              error: (e, _) => LoadError(
                onRetry: () => ref.invalidate(invoicePageProvider(filter)),
              ),
              data: (p) => Column(
                children: [
                  if (p.fromCache)
                    const Text(
                      'Data cache; sambungkan jaringan untuk status terbaru.',
                    ),
                  if (p.items.isEmpty)
                    const EmptyState(
                      title: 'Belum ada invoice',
                      description: 'Belum ada invoice pada periode ini.',
                      icon: Icons.receipt_long_outlined,
                    ),
                  for (final i in p.items)
                    WorkshopRecordCard(
                      icon: Icons.receipt_long_outlined,
                      title: i.text('invoiceNo'),
                      description:
                          '${i.text('vehiclePlate')} • ${i.text('serviceName')}\n${rupiah(i.number('grandTotal'))}',
                      status: PaymentBadge(status: i.text('status')),
                      onTap: () => context.push(
                        '/${admin ? 'admin' : 'customer'}/invoices/${i.id}',
                      ),
                    ),
                  if (p.hasMore)
                    TextButton(
                      onPressed: () => setState(() => cursor = p.cursor),
                      child: const Text('Halaman berikutnya'),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => cursor = null);
                ref.invalidate(invoicePageProvider);
              },
              child: const Text('Muat ulang dari awal'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmAction(BuildContext context, String message) =>
    confirmWorkshopAction(context, message);

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends ConsumerState<InvoiceDetailScreen> {
  final amount = TextEditingController(), notes = TextEditingController();
  String method = 'cash';
  String? key, error;
  bool busy = false;
  DocumentSnapshot<Map<String, dynamic>>? auditCursor;
  @override
  void dispose() {
    amount.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> record(Invoice invoice, String kind) => run(() async {
    if (!await confirmAction(
      context,
      kind == 'payment'
          ? 'Pastikan uang tunai diterima atau transfer sudah diverifikasi manual. Catat pembayaran ini?'
          : '$kind manual bersifat final. Pastikan alasan dan pengembalian uang sudah diperiksa.',
    )) {
      return;
    }
    final repo = ref.read(paymentRepositoryProvider);
    key ??= repo.newKey(); // Retain after failure for ambiguous commit retry.
    await repo.record(
      widget.id,
      key!,
      invoice.number('revision'),
      kind: kind,
      amount: kind == 'payment'
          ? int.parse(amount.text)
          : kind == 'refund'
          ? invoice.number('paidAmount')
          : 0,
      method: kind == 'void' ? 'none' : method,
      reason: notes.text,
    );
    key = null;
    amount.clear();
    notes.clear();
    ref.invalidate(invoicePageProvider);
    ref.invalidate(invoiceAuditProvider);
  });
  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authSessionProvider).role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail invoice')),
      bottomNavigationBar: MobileNavigation(role: admin ? 'admin' : 'customer'),
      body: WorkshopBody(
        child: ref
            .watch(invoiceProvider(widget.id))
            .when(
              loading: () => const LoadingState(),
              error: (e, _) => LoadError(
                onRetry: () => ref.invalidate(invoiceProvider(widget.id)),
              ),
              data: (i) => i == null
                  ? const Center(child: Text('Invoice belum terbit.'))
                  : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(20),
                      children: [
                        ContentSection(
                          title: 'Invoice servis',
                          children: [
                            SelectableText(
                              i.text('invoiceNo'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${i.text('vehiclePlate')} • ${i.text('serviceName')}',
                            ),
                            const SizedBox(height: 12),
                            PaymentBadge(status: i.text('status')),
                            const SizedBox(height: 8),
                            Text(
                              'Terbit: ${historyDate(i.date('createdAt'))}\nLunas: ${historyDate(i.date('paidAt'))}',
                            ),
                            Text(
                              'Metode: ${i.text('method') == 'cash'
                                  ? 'Tunai'
                                  : i.text('method') == 'transfer'
                                  ? 'Transfer manual'
                                  : 'Belum dicatat'}',
                            ),
                          ],
                        ),
                        ContentSection(
                          title: 'Rincian biaya',
                          children: [
                            Text('Jasa: ${rupiah(i.number('laborPrice'))}'),
                            const SizedBox(height: 12),
                            for (final p
                                in (i.data['parts'] as List).cast<Map>())
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${p['name']} • ${p['kind']} • ${p['quantity']} x ${rupiah(p['sellPrice'] as int)}',
                                ),
                              ),
                            const Divider(),
                            for (final p in [
                              ('Subtotal', 'subtotal'),
                              ('Diskon', 'discount'),
                              ('Biaya tambahan', 'fee'),
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Text(
                                  '${p.$1}: ${rupiah(i.number(p.$2))}',
                                ),
                              ),
                          ],
                        ),
                        ContentSection(
                          title: 'Ringkasan pembayaran',
                          children: [
                            Text(
                              'Total: ${rupiah(i.number('grandTotal'))}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            for (final p in [
                              ('Dibayar net', 'paidAmount'),
                              ('Kembalian kumulatif', 'change'),
                              ('Sisa', 'due'),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${p.$1}: ${rupiah(i.number(p.$2))}',
                                ),
                              ),
                            Text(
                              'Petugas: ${i.text('recordedBy')}\nCatatan: ${i.text('notes')}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => run(() async {
                                      await Printing.layoutPdf(
                                        onLayout: (_) => buildInvoicePdf(i),
                                      );
                                    }),
                              child: const Text('Buka / cetak PDF'),
                            ),
                            Builder(
                              builder: (buttonContext) => OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => run(() async {
                                        final box =
                                            buttonContext.findRenderObject()!
                                                as RenderBox;
                                        final bounds =
                                            box.localToGlobal(Offset.zero) &
                                            box.size;
                                        await Printing.sharePdf(
                                          bytes: await buildInvoicePdf(i),
                                          filename:
                                              '${i.text('invoiceNo')}.pdf',
                                          bounds: bounds,
                                        );
                                      }),
                                child: const Text('Bagikan PDF'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (admin &&
                            [
                              'unpaid',
                              'partial',
                              'paid',
                            ].contains(i.text('status'))) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: amount,
                            enabled: !busy,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Uang diterima (integer rupiah)',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: method,
                            decoration: const InputDecoration(
                              labelText: 'Metode pembayaran',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'cash',
                                child: Text('Tunai'),
                              ),
                              DropdownMenuItem(
                                value: 'transfer',
                                child: Text('Transfer manual'),
                              ),
                            ],
                            onChanged: busy
                                ? null
                                : (v) => setState(() => method = v!),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notes,
                            enabled: !busy,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText:
                                  'Catatan / referensi transfer / alasan',
                            ),
                          ),
                          if (i.text('status') != 'paid')
                            FilledButton(
                              onPressed: busy
                                  ? null
                                  : () => record(i, 'payment'),
                              child: const Text('Catat pembayaran'),
                            ),
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => record(
                                    i,
                                    i.text('status') == 'unpaid'
                                        ? 'void'
                                        : 'refund',
                                  ),
                            child: Text(
                              i.text('status') == 'unpaid'
                                  ? 'Void invoice'
                                  : 'Refund penuh manual',
                            ),
                          ),
                        ],
                        if (busy) const LinearProgressIndicator(),
                        if (error != null)
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const Divider(),
                        const Text('Audit pembayaran'),
                        ref
                            .watch(
                              invoiceAuditProvider((
                                id: widget.id,
                                cursor: auditCursor,
                              )),
                            )
                            .when(
                              loading: () => const LoadingState(),
                              error: (e, _) => Text('Gagal memuat audit: $e'),
                              data: (p) => Column(
                                children: [
                                  for (final e in p.docs)
                                    ListTile(
                                      title: Text(
                                        '${e['kind']} • ${rupiah(e['amount'] as int)}',
                                      ),
                                      subtitle: Text(
                                        '${e['recordedBy']} • ${historyDate((e['paidAt'] as Timestamp?)?.toDate())}\n${e['notes']}',
                                      ),
                                    ),
                                  if (p.docs.length == 20)
                                    TextButton(
                                      onPressed: () => setState(
                                        () => auditCursor = p.docs.last,
                                      ),
                                      child: const Text('Audit berikutnya'),
                                    ),
                                ],
                              ),
                            ),
                      ],
                    ),
            ),
      ),
    );
  }
}

final invoiceAuditProvider = FutureProvider.autoDispose
    .family<
      QuerySnapshot<Map<String, dynamic>>,
      ({String id, DocumentSnapshot<Map<String, dynamic>>? cursor})
    >((ref, f) {
      Query<Map<String, dynamic>> q = ref
          .watch(paymentRepositoryProvider)
          .invoices
          .doc(f.id)
          .collection('payments')
          .orderBy('revision', descending: true);
      if (f.cursor != null) q = q.startAfterDocument(f.cursor!);
      return q.limit(20).get();
    });
