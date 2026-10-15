import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_router.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/mobile_navigation.dart';
import 'technicians_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final role = session.role!.name;
    final provider = ordersPageProvider(cursors.last);
    return Scaffold(
      appBar: AppBar(title: const Text('Service Order')),
      bottomNavigationBar: MobileNavigation(role: role),
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
                  if (role == 'admin')
                    OutlinedButton(
                      onPressed: () => context.go('/admin/technicians'),
                      child: const Text('Kelola teknisi'),
                    ),
                  if (page.items.isEmpty)
                    const Text('Belum ada Service Order di halaman ini.'),
                  for (final order in page.items)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${order.text('vehicleName')} • ${order.text('vehiclePlate')}',
                        ),
                        subtitle: Text(
                          '${order.status.label}\n${order.text('serviceName')}',
                        ),
                        onTap: () => context.go('/$role/orders/${order.id}'),
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

class RetryLoad extends StatelessWidget {
  const RetryLoad({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onRetry,
      child: const Text('Gagal memuat. Coba lagi'),
    ),
  );
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
        title: const Text('Detail Service Order'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/$role/${role == 'technician' ? 'jobs' : 'orders'}'),
        ),
      ),
      bottomNavigationBar: MobileNavigation(role: role),
      body: SafeArea(
        child: ref
            .watch(provider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      order.text('vehicleName'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(order.text('vehiclePlate')),
                    Text('Layanan: ${order.text('serviceName')}'),
                    Text('Keluhan: ${order.text('complaint')}'),
                    Text('Status: ${order.status.label}'),
                    Text(
                      'Teknisi: ${order.technicianId ?? 'Belum ditugaskan'}',
                    ),
                    Text(
                      'Diperbarui: ${order.date('updatedAt')?.toLocal() ?? 'Menyinkronkan…'}',
                    ),
                    const SizedBox(height: 16),
                    for (final entry in order.checklist.entries)
                      Text(
                        '${entry.value ? '✓' : '○'} ${inspectionLabel(entry.key)}',
                      ),
                    Text('Diagnosis: ${order.text('diagnosis')}'),
                    Text('Tindakan: ${order.text('actions')}'),
                    Text('Catatan: ${order.text('notes')}'),
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
                                      title: Text('${next.label}?'),
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
                          child: Text(next.label),
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
    appBar: AppBar(title: const Text('Catatan kerja')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final key in inspectionKeys)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(inspectionLabel(key)),
              value: checks[key],
              onChanged: busy ? null : (v) => setState(() => checks[key] = v!),
            ),
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
          if (error != null) Text(error!),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
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
            child: Text(busy ? 'Menyimpan…' : 'Simpan'),
          ),
        ],
      ),
    ),
  );
}
