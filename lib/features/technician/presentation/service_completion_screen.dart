import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/data/inventory_repository.dart';
import '../../../core/data/service_order_repository.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/workshop_ui.dart';
import '../../auth/data/auth_repository.dart';
import 'service_orders_screen.dart';
import 'technician_form_ui.dart';
import 'technician_task_ui.dart';

class ServiceCompletionScreen extends ConsumerStatefulWidget {
  const ServiceCompletionScreen({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<ServiceCompletionScreen> createState() => _CompletionState();
}

class _CompletionState extends ConsumerState<ServiceCompletionScreen> {
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  bool busy = false;
  String? error;

  Future<void> submit(ServiceOrder order) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final yes = await confirmWorkshopAction(
      context,
      'Ajukan hasil pekerjaan untuk diperiksa admin? Servis belum langsung selesai.',
      title: 'Ajukan selesai?',
      confirmLabel: 'Lanjutkan',
    );
    if (!mounted) return;
    if (!yes) {
      setState(() => busy = false);
      return;
    }
    try {
      await ref
          .read(serviceOrderRepositoryProvider)
          .updateWork(
            order.id,
            order.revision,
            status: ServiceOrderStatus.awaitingApproval,
            checklist: order.checklist,
            diagnosis: order.text('diagnosis'),
            actions: order.text('actions'),
            notes: order.text('notes'),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error =
              'Gagal mengajukan: $e. Periksa status terbaru sebelum mencoba lagi.';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!session.isAuthenticated) return const SizedBox.shrink();
    final orderProvider = serviceOrderProvider(widget.orderId);
    final partsProvider = orderInventoryProvider((
      cursor: cursors.last,
      orderId: widget.orderId,
      requests: false,
    ));
    final state = ref.watch(orderProvider);
    final current = state.asData?.value;
    final own =
        session.role == UserRole.technician &&
        current?.technicianId == session.userId;
    final canSubmit =
        own &&
        current != null &&
        current.status.canTransitionTo(
          ServiceOrderStatus.awaitingApproval,
          admin: false,
        );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Penyelesaian Servis'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang ringkasan',
            onPressed: () {
              ref.invalidate(orderProvider);
              ref.invalidate(partsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: canSubmit
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: busy ? null : () => submit(current),
                  icon: const Icon(Icons.check),
                  label: Text(busy ? 'Mengajukan…' : 'Ajukan Selesai'),
                ),
              ),
            )
          : null,
      body: WorkshopBody(
        showWave: true,
        child: state.when(
          loading: () => const LoadingState(),
          error: (_, _) =>
              RetryLoad(onRetry: () => ref.invalidate(orderProvider)),
          data: (order) {
            if (order == null) {
              return const EmptyState(
                title: 'Tugas belum tersedia',
                description: 'Kembali ke daftar tugas dan muat ulang.',
                icon: Icons.assignment_outlined,
              );
            }
            if (session.role != UserRole.technician ||
                order.technicianId != session.userId) {
              return const EmptyState(
                title: 'Tugas tidak dapat diakses',
                description: 'Ringkasan hanya untuk tugas Anda.',
                icon: Icons.lock_outline,
              );
            }
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                const TechnicianFormIntro(
                  art: WorkshopArt.completion,
                  height: 112,
                  description:
                      'Ringkasan hasil servis untuk pengajuan penyelesaian pekerjaan.',
                ),
                TaskVehicleCard(
                  order: order,
                  onTap: Navigator.canPop(context)
                      ? () => Navigator.pop(context)
                      : null,
                ),
                const SizedBox(height: 12),
                TaskSummaryCard(
                  title: 'Diagnosis',
                  icon: Icons.assignment_outlined,
                  children: [
                    Text(
                      order.text('diagnosis').isEmpty
                          ? 'Belum dicatat.'
                          : order.text('diagnosis'),
                    ),
                  ],
                ),
                TaskSummaryCard(
                  title: 'Tindakan Servis',
                  icon: Icons.build_outlined,
                  children: [
                    Text(
                      order.text('actions').isEmpty
                          ? 'Belum dicatat.'
                          : order.text('actions'),
                    ),
                  ],
                ),
                TaskSummaryCard(
                  title: 'Sparepart Terpakai',
                  icon: Icons.inventory_2_outlined,
                  children: [
                    ref
                        .watch(partsProvider)
                        .when(
                          loading: () => const LoadingState(),
                          error: (_, _) => RetryLoad(
                            onRetry: () => ref.invalidate(partsProvider),
                          ),
                          data: (page) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (page.items.isEmpty)
                                const Text(
                                  'Belum ada pemakaian sparepart pada halaman ini.',
                                ),
                              for (final row in page.items)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${row['name']} (${row['sku']})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${row['kind'] == 'reversal' ? 'Dikembalikan' : 'Dipakai'}: ${row['quantity']} ${row['unit']}',
                                      ),
                                    ],
                                  ),
                                ),
                              if (page.hasMore || cursors.length > 1)
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
                    Text(
                      'Pemakaian dan reversal terpisah; maksimal 20 catatan per halaman.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TechnicianTimeline(order: order),
                const SizedBox(height: 12),
                Text(
                  'Checklist tersimpan: ${order.checklist.values.where((value) => value).length}/${inspectionKeys.length} pemeriksaan.',
                ),
                if (!order.status.terminal)
                  const Text(
                    'Checklist, diagnosis dan tindakan harus lengkap. Pengajuan tetap memerlukan pemeriksaan serta persetujuan admin.',
                  ),
                if (order.text('notes').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TaskSummaryCard(
                    title: 'Catatan',
                    icon: Icons.chat_bubble_outline,
                    children: [Text(order.text('notes'))],
                  ),
                ],
                if (['inProgress', 'paused'].contains(order.status.name))
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WorkEditor(order: order),
                            ),
                          ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ubah checklist dan catatan'),
                  ),
                if (error != null)
                  Semantics(liveRegion: true, child: Text(error!)),
              ],
            );
          },
        ),
      ),
    );
  }
}
