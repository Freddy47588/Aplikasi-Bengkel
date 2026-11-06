import '../../../core/widgets/workshop_ui.dart';
import 'technician_task_ui.dart';
import 'technician_form_ui.dart';
import 'service_completion_screen.dart';
import '../../../app/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/mobile_navigation.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/service_timeline.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/models/service_history.dart';
import 'technicians_screen.dart';
import '../../inventory/presentation/order_parts_screen.dart';

final ordersPageProvider = StreamProvider.autoDispose
    .family<RecordPage<ServiceOrder>, DocumentSnapshot<Map<String, dynamic>>?>((
      ref,
      cursor,
    ) {
      if (!ref.watch(authSessionProvider).isAuthenticated) {
        return Stream.value(const RecordPage([], null, false));
      }
      return ref
          .watch(serviceOrderRepositoryProvider)
          .watchOrders(after: cursor);
    });

class ServiceOrdersScreen extends ConsumerStatefulWidget {
  const ServiceOrdersScreen({super.key});
  @override
  ConsumerState<ServiceOrdersScreen> createState() => _OrdersState();
}

class _OrdersState extends ConsumerState<ServiceOrdersScreen> {
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  final search = TextEditingController();
  String query = '';
  bool showFilters = false;
  ServiceOrderStatus? status;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Widget technicianList(BuildContext context, String uid) {
    final provider = ordersPageProvider(cursors.last);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Daftar Tugas'),
        leading: IconButton(
          tooltip: 'Kembali ke dashboard',
          onPressed: () => context.go('/technician/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const MobileNavigation(role: 'technician'),
      body: WorkshopBody(
        showWave: true,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const TechnicianTaskIntro(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) =>
                        setState(() => query = value.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      labelText: 'Cari SO / kendaraan',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  height: 56,
                  child: IconButton.outlined(
                    tooltip: 'Filter tugas',
                    isSelected: showFilters,
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => setState(() => showFilters = !showFilters),
                    icon: const Icon(Icons.tune),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pencarian dan filter berlaku pada halaman ini (maks. 20 tugas).',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (showFilters) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<ServiceOrderStatus>(
                initialValue: status,
                isExpanded: true,
                itemHeight: null,
                decoration: const InputDecoration(labelText: 'Status tugas'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Semua status'),
                  ),
                  for (final value in ServiceOrderStatus.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(technicianStatusLabel(value)),
                    ),
                ],
                onChanged: (value) => setState(() => status = value),
              ),
            ],
            const SizedBox(height: 12),
            ref
                .watch(provider)
                .when(
                  loading: () => const LoadingState(),
                  error: (_, _) =>
                      RetryLoad(onRetry: () => ref.invalidate(provider)),
                  data: (page) {
                    final own = page.items
                        .where((o) => o.technicianId == uid)
                        .toList();
                    final visible = own.where(
                      (o) =>
                          (status == null || o.status == status) &&
                          [
                            o.id,
                            o.text('vehiclePlate'),
                            o.text('vehicleName'),
                            o.text('serviceName'),
                          ].any((text) => text.toLowerCase().contains(query)),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (own.isEmpty)
                          const EmptyState(
                            title: 'Belum ada pekerjaan',
                            description:
                                'Belum ada Service Order di halaman ini.',
                            icon: Icons.car_repair_outlined,
                          )
                        else if (visible.isEmpty)
                          const EmptyState(
                            title: 'Tugas belum ditemukan',
                            description:
                                'Tidak ada tugas sesuai pencarian dan filter pada halaman ini. Coba halaman lain atau ubah filter.',
                            icon: Icons.search_off,
                          ),
                        for (final order in visible)
                          TechnicianTaskCard(
                            order: order,
                            onTap: () =>
                                context.go('/technician/orders/${order.id}'),
                          ),
                        PageButtons(
                          page: cursors.length,
                          hasMore: page.hasMore,
                          previous: () => setState(() => cursors.removeLast()),
                          next: () => setState(() => cursors.add(page.cursor)),
                        ),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    if (role == 'technician') return technicianList(context, session.userId);
    final provider = ordersPageProvider(cursors.last);
    return Scaffold(
      appBar: AppBar(title: const Text('Service Order')),
      bottomNavigationBar: MobileNavigation(role: role),
      body: WorkshopBody(
        child: ref
            .watch(provider)
            .when(
              loading: () => const LoadingState(),
              error: (_, _) =>
                  RetryLoad(onRetry: () => ref.invalidate(provider)),
              data: (page) => ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                children: [
                  PageIntro(
                    showTitle: false,
                    art: WorkshopArt.checklist,
                    title: role == 'technician'
                        ? 'Daftar tugas Anda'
                        : 'Daftar service order',
                    description:
                        'Pantau status pekerjaan dan buka rincian servis kendaraan.',
                  ),
                  if (role == 'admin')
                    OutlinedButton(
                      onPressed: () => context.go('/admin/technicians'),
                      child: const Text('Kelola teknisi'),
                    ),
                  if (page.items.isEmpty)
                    const EmptyState(
                      title: 'Belum ada pekerjaan',
                      description: 'Belum ada Service Order di halaman ini.',
                      icon: Icons.car_repair_outlined,
                    ),
                  for (final order in page.items)
                    WorkshopRecordCard(
                      icon: Icons.car_repair_outlined,
                      title:
                          '${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                      description:
                          '${order.text('serviceName')}\nTeknisi: ${order.text('technicianName').isEmpty ? 'Belum tercatat' : order.text('technicianName')}',
                      status: StatusChip(
                        label: order.status.label,
                        tone: orderStatusTone(order.status),
                      ),
                      onTap: () => context.go('/$role/orders/${order.id}'),
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

class RetryLoad extends StatelessWidget {
  const RetryLoad({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => LoadError(onRetry: onRetry);
}

class PageButtons extends StatelessWidget {
  const PageButtons({
    super.key,
    required this.page,
    required this.hasMore,
    required this.previous,
    required this.next,
  });
  final int page;
  final bool hasMore;
  final VoidCallback previous, next;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      TextButton(
        onPressed: page > 1 ? previous : null,
        child: const Text('Sebelumnya'),
      ),
      Text('Halaman $page'),
      TextButton(
        onPressed: hasMore ? next : null,
        child: const Text('Berikutnya'),
      ),
    ],
  );
}

class ServiceOrderDetailScreen extends ConsumerStatefulWidget {
  const ServiceOrderDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ServiceOrderDetailScreen> createState() => _OrderDetailState();
}

class _OrderDetailState extends ConsumerState<ServiceOrderDetailScreen> {
  bool busy = false;
  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Permintaan gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    final provider = serviceOrderProvider(widget.id);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: role == 'technician' ? Colors.white : null,
        title: Text(
          role == 'technician' ? 'Detail Tugas' : 'Detail Service Order',
        ),
        leading: IconButton(
          tooltip: 'Kembali ke daftar pekerjaan',
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/$role/${role == 'technician' ? 'jobs' : 'orders'}'),
        ),
      ),
      bottomNavigationBar: MobileNavigation(role: role),
      body: WorkshopBody(
        showWave: role == 'technician',
        child: ref
            .watch(provider)
            .when(
              loading: () => const LoadingState(),
              error: (_, _) =>
                  RetryLoad(onRetry: () => ref.invalidate(provider)),
              data: (order) {
                if (order == null) {
                  return const Center(
                    child: Text('Service Order belum tersedia.'),
                  );
                }
                Future<void> transition(ServiceOrderStatus next) => run(
                  () => ref
                      .read(serviceOrderRepositoryProvider)
                      .updateWork(
                        order.id,
                        order.revision,
                        status: next,
                        checklist: order.checklist,
                        diagnosis: order.text('diagnosis'),
                        actions: order.text('actions'),
                        notes: order.text('notes'),
                      ),
                );
                if (role == 'technician') {
                  if (order.technicianId != session.userId) {
                    return const EmptyState(
                      title: 'Tugas tidak dapat diakses',
                      description:
                          'Anda hanya dapat membuka tugas yang ditugaskan kepada Anda.',
                      icon: Icons.lock_outline,
                    );
                  }
                  return TechnicianTaskDetail(
                    order: order,
                    busy: busy,
                    onChecklist: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkEditor(order: order),
                      ),
                    ),
                    onParts: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderPartsScreen(orderId: order.id),
                      ),
                    ),
                    onHistory: () =>
                        context.go('/technician/history/${order.id}'),
                    onCompletion: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceCompletionScreen(orderId: order.id),
                      ),
                    ),
                    onTransition: (next) async {
                      if (next == ServiceOrderStatus.awaitingApproval) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ServiceCompletionScreen(orderId: order.id),
                          ),
                        );
                        return;
                      }
                      final yes = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          scrollable: true,
                          title: Text(
                            '${workActionLabel(next, order.status)}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Kembali'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Lanjutkan'),
                            ),
                          ],
                        ),
                      );
                      if (yes == true && mounted) await transition(next);
                    },
                  );
                }
                return ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: [
                    WorkshopRecordCard(
                      title: order.text('vehiclePlate'),
                      description:
                          '${order.text('vehicleName')}\n${order.text('serviceName')}',
                      icon: Icons.car_repair_outlined,
                      status: StatusChip(
                        label: order.status.label,
                        tone: orderStatusTone(order.status),
                      ),
                    ),
                    ContentSection(
                      title: 'Keluhan kendaraan',
                      children: [Text(order.text('complaint'))],
                    ),
                    ContentSection(
                      title: 'Penugasan teknisi',
                      children: [
                        Text(
                          'Teknisi: ${order.text('technicianName').isNotEmpty
                              ? order.text('technicianName')
                              : order.technicianId == null
                              ? 'Belum ditugaskan'
                              : 'Teknisi telah ditugaskan'}',
                        ),
                      ],
                    ),
                    ExpansionTile(
                      title: const Text('Referensi penugasan'),
                      children: [
                        SelectableText('Service Order: ${order.id}'),
                        if (order.technicianId != null)
                          SelectableText('ID teknisi: ${order.technicianId}'),
                      ],
                    ),
                    Text('Diperbarui: ${historyDate(order.date('updatedAt'))}'),
                    const SizedBox(height: 16),
                    ServiceTimeline(order: order),
                    Text(
                      'Biaya jasa: ${order.data['laborPrice'] == null ? 'Belum dicatat' : rupiah(order.data['laborPrice'] as int)}',
                    ),
                    if (order.status == ServiceOrderStatus.completed &&
                        role != 'technician')
                      OutlinedButton(
                        onPressed: () => context.push(
                          role == 'admin'
                              ? Uri(
                                  path: '/admin/invoices',
                                  queryParameters: {'orderId': order.id},
                                ).toString()
                              : '/customer/invoices/${order.id}',
                        ),
                        child: Text(
                          role == 'admin'
                              ? 'Pembayaran / terbitkan invoice'
                              : 'Lihat invoice',
                        ),
                      ),
                    if (order.status == ServiceOrderStatus.completed)
                      TextButton(
                        onPressed: () =>
                            context.go('/$role/history/${order.id}'),
                        child: const Text('Buka riwayat dan rincian biaya'),
                      ),
                    if (role == 'admin' && !order.status.terminal)
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final price = await showDialog<int>(
                                  context: context,
                                  builder: (_) => LaborPriceDialog(
                                    initial: order.data['laborPrice'] as int?,
                                  ),
                                );
                                if (price != null && mounted) {
                                  await run(
                                    () => ref
                                        .read(serviceOrderRepositoryProvider)
                                        .setLaborPrice(
                                          order.id,
                                          order.revision,
                                          price,
                                        ),
                                  );
                                }
                              },
                        child: const Text('Catat biaya jasa'),
                      ),
                    ContentSection(
                      title: 'Checklist pekerjaan',
                      children: [
                        for (final entry in order.checklist.entries)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              entry.value
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                            ),
                            title: Text(inspectionLabel(entry.key)),
                            subtitle: Text(
                              entry.value
                                  ? 'Sudah diperiksa'
                                  : 'Belum diperiksa',
                            ),
                          ),
                      ],
                    ),
                    ContentSection(
                      title: 'Pemeriksaan & tindakan',
                      children: [
                        Text('Diagnosis: ${order.text('diagnosis')}'),
                        const SizedBox(height: 12),
                        Text('Tindakan: ${order.text('actions')}'),
                        const SizedBox(height: 12),
                        Text('Catatan: ${order.text('notes')}'),
                      ],
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderPartsScreen(orderId: order.id),
                        ),
                      ),
                      child: const Text('Sparepart dan permintaan'),
                    ),
                    if (busy) const LinearProgressIndicator(),
                    if (role == 'admin' &&
                        [
                          'queued',
                          'assigned',
                          'paused',
                        ].contains(order.status.name))
                      FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final target = await Navigator.of(context)
                                    .push<String>(
                                      MaterialPageRoute(
                                        builder: (_) => const TechniciansScreen(
                                          select: true,
                                        ),
                                      ),
                                    );
                                if (target != null && mounted) {
                                  await run(
                                    () => ref
                                        .read(serviceOrderRepositoryProvider)
                                        .assign(
                                          order.id,
                                          target,
                                          order.revision,
                                        ),
                                  );
                                }
                              },
                        child: const Text('Assign / alihkan teknisi'),
                      ),
                    if (role == 'technician' &&
                        [
                          ServiceOrderStatus.inProgress,
                          ServiceOrderStatus.paused,
                        ].contains(order.status))
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WorkEditor(order: order),
                                ),
                              ),
                        child: const Text('Checklist dan catatan kerja'),
                      ),
                    for (final next in ServiceOrderStatus.values.where(
                      (s) => order.status.canTransitionTo(
                        s,
                        admin: role == 'admin',
                      ),
                    ))
                      if (role != 'customer')
                        OutlinedButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      scrollable: true,
                                      title: Text(
                                        '${workActionLabel(next, order.status)}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(c, false),
                                          child: const Text('Kembali'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(c, true),
                                          child: const Text('Lanjutkan'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes == true && mounted) {
                                    await transition(next);
                                  }
                                },
                          child: Text(workActionLabel(next, order.status)),
                        ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

String inspectionLabel(String key) => switch (key) {
  'vehicleChecked' => 'Kondisi kendaraan diperiksa',
  'safetyChecked' => 'Keselamatan diperiksa',
  _ => 'Hasil pekerjaan diperiksa',
};

StatusChipTone orderStatusTone(ServiceOrderStatus status) => switch (status) {
  ServiceOrderStatus.completed => StatusChipTone.success,
  ServiceOrderStatus.cancelled => StatusChipTone.neutral,
  ServiceOrderStatus.queued ||
  ServiceOrderStatus.paused ||
  ServiceOrderStatus.awaitingApproval => StatusChipTone.warning,
  _ => StatusChipTone.info,
};

String workActionLabel(ServiceOrderStatus next, ServiceOrderStatus current) =>
    switch (next) {
      ServiceOrderStatus.inProgress =>
        current == ServiceOrderStatus.paused
            ? 'Lanjutkan pengerjaan'
            : current == ServiceOrderStatus.awaitingApproval
            ? 'Kembalikan untuk perbaikan'
            : 'Mulai pengerjaan',
      ServiceOrderStatus.paused => 'Jeda pengerjaan',
      ServiceOrderStatus.awaitingApproval => 'Ajukan selesai',
      ServiceOrderStatus.completed => 'Setujui penyelesaian',
      ServiceOrderStatus.cancelled => 'Batalkan pekerjaan',
      ServiceOrderStatus.assigned => 'Kembalikan untuk perbaikan',
      _ => next.label,
    };

class WorkEditor extends ConsumerStatefulWidget {
  const WorkEditor({super.key, required this.order});
  final ServiceOrder order;
  @override
  ConsumerState<WorkEditor> createState() => _WorkEditorState();
}

class _WorkEditorState extends ConsumerState<WorkEditor> {
  late final diagnosis = TextEditingController(
    text: widget.order.text('diagnosis'),
  );
  late final actions = TextEditingController(
    text: widget.order.text('actions'),
  );
  late final notes = TextEditingController(text: widget.order.text('notes'));
  late final checks = widget.order.checklist;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    diagnosis.dispose();
    actions.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Checklist Pekerjaan'),
    ),
    body: WorkshopBody(
      showWave: true,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const TechnicianFormIntro(
            art: WorkshopArt.checklist,
            description:
                'Isi checklist pemeriksaan sesuai prosedur servis kendaraan.',
          ),
          TaskVehicleCard(
            order: widget.order,
            onTap: Navigator.canPop(context)
                ? () => Navigator.pop(context)
                : null,
          ),
          const SizedBox(height: 18),
          Text(
            'Daftar Checklist Servis',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final key in inspectionKeys)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.blueBorder),
              ),
              child: CheckboxListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                activeColor: AppColors.secondary,
                checkColor: Colors.white,
                side: const BorderSide(color: AppColors.muted, width: 2),
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  inspectionLabel(key),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(inspectionDescription(key)),
                value: checks[key],
                onChanged: busy
                    ? null
                    : (v) => setState(() => checks[key] = v!),
              ),
            ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Diagnosis, tindakan dan catatan'),
            tilePadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (controller, label, max) in [
                (diagnosis, 'Diagnosis', 2000),
                (actions, 'Tindakan', 2000),
                (notes, 'Catatan', 4000),
              ])
                TextField(
                  controller: controller,
                  enabled: !busy,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: max,
                  decoration: InputDecoration(labelText: label),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null) Text(error!),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            onPressed: busy
                ? null
                : () async {
                    if (busy) return;
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await ref
                          .read(serviceOrderRepositoryProvider)
                          .updateWork(
                            widget.order.id,
                            widget.order.revision,
                            checklist: checks,
                            diagnosis: diagnosis.text,
                            actions: actions.text,
                            notes: notes.text,
                          );
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          error =
                              'Gagal menyimpan: $e. Jika tugas berubah, kembali dan buka ulang.';
                          busy = false;
                        });
                      }
                    }
                  },
            label: Text(busy ? 'Menyimpan…' : 'Simpan Checklist'),
          ),
        ],
      ),
    ),
  );
}

class LaborPriceDialog extends StatefulWidget {
  const LaborPriceDialog({super.key, this.initial});
  final int? initial;
  @override
  State<LaborPriceDialog> createState() => _LaborPriceState();
}

class _LaborPriceState extends State<LaborPriceDialog> {
  late final controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Snapshot biaya jasa'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan rupiah bulat, termasuk 0 untuk jasa gratis. Biaya terkunci setelah servis selesai.',
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Biaya jasa (Rp)',
              errorText: error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kembali'),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(controller.text.trim());
          if (value == null || value < 0 || value > 1000000000) {
            setState(() => error = 'Masukkan 0 sampai 1000000000 rupiah.');
            return;
          }
          Navigator.pop(context, value);
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
