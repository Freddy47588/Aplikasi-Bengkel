import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/data/inventory_repository.dart';
import '../../../core/models/service_history.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/service_timeline.dart';
import '../../../core/widgets/status_chip.dart';
import 'service_orders_screen.dart';
import 'technician_form_ui.dart';

class AdminRecordCard extends StatelessWidget {
  const AdminRecordCard({
    super.key,
    required this.title,
    required this.lines,
    required this.icon,
    required this.status,
    this.onTap,
    this.enabled = true,
  });
  final String title;
  final List<String> lines;
  final IconData icon;
  final Widget status;
  final VoidCallback? onTap;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.blueBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.blueSurface,
                child: Icon(icon, color: AppColors.secondary, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .42,
                            ),
                            child: status,
                          ),
                        ],
                      )
                    else ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      status,
                    ],
                    for (final line in lines)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          line,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              if (onTap != null && enabled) ...[
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdminOrderDetail extends StatelessWidget {
  const AdminOrderDetail({
    super.key,
    required this.order,
    required this.busy,
    required this.onAssign,
    required this.onPrice,
    required this.onParts,
    required this.onInvoice,
    required this.onHistory,
    required this.onTransition,
  });
  final ServiceOrder order;
  final bool busy;
  final VoidCallback onAssign, onPrice, onParts, onInvoice, onHistory;
  final void Function(ServiceOrderStatus) onTransition;
  @override
  Widget build(BuildContext context) {
    final assignable = [
      'queued',
      'assigned',
      'paused',
    ].contains(order.status.name);
    final transitions = ServiceOrderStatus.values.where(
      (s) => order.status.canTransitionTo(s, admin: true),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        AdminRecordCard(
          title: order.id,
          lines: const [],
          icon: Icons.assignment_outlined,
          status: StatusChip(
            label: order.status.label,
            tone: orderStatusTone(order.status),
          ),
        ),
        const SizedBox(height: 6),
        TaskSummaryCard(
          title: 'Informasi Kendaraan',
          icon: Icons.directions_car_outlined,
          children: [
            Text(
              order.text('vehiclePlate'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(order.text('vehicleName')),
          ],
        ),
        TaskSummaryCard(
          title: 'Penugasan Teknisi',
          icon: Icons.engineering_outlined,
          children: [
            Text(
              order.text('technicianName').isNotEmpty
                  ? order.text('technicianName')
                  : order.technicianId == null
                  ? 'Belum ditugaskan'
                  : 'Teknisi telah ditugaskan',
            ),
          ],
        ),
        TaskSummaryCard(
          title: 'Rincian Pekerjaan',
          icon: Icons.build_outlined,
          children: [
            Text(order.text('serviceName')),
            const SizedBox(height: 4),
            Text(
              'Biaya jasa: ${order.data['laborPrice'] is int ? rupiah(order.data['laborPrice'] as int) : 'Belum dicatat'}',
            ),
          ],
        ),
        AdminOrderParts(orderId: order.id),
        const SizedBox(height: 6),
        AdminOrderTimeline(order: order),
        const SizedBox(height: 16),
        if (busy) const LinearProgressIndicator(),
        if (assignable)
          FilledButton.icon(
            onPressed: busy ? null : onAssign,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Assign / alihkan teknisi'),
          ),
        for (final next in transitions.where(
          (s) => s == ServiceOrderStatus.completed,
        ))
          FilledButton.icon(
            onPressed: busy ? null : () => onTransition(next),
            icon: const Icon(Icons.check),
            label: Text(workActionLabel(next, order.status)),
          ),
        if (!order.status.terminal)
          if (!assignable &&
              order.status != ServiceOrderStatus.awaitingApproval)
            FilledButton.icon(
              onPressed: busy ? null : onPrice,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Catat biaya jasa'),
            )
          else
            OutlinedButton.icon(
              onPressed: busy ? null : onPrice,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Catat biaya jasa'),
            ),
        OutlinedButton.icon(
          onPressed: onParts,
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Sparepart dan permintaan'),
        ),
        for (final next in transitions.where(
          (s) => s != ServiceOrderStatus.completed,
        ))
          OutlinedButton(
            onPressed: busy ? null : () => onTransition(next),
            child: Text(workActionLabel(next, order.status)),
          ),
        if (order.status == ServiceOrderStatus.completed) ...[
          OutlinedButton(
            onPressed: onInvoice,
            child: const Text('Pembayaran / terbitkan invoice'),
          ),
          TextButton(
            onPressed: onHistory,
            child: const Text('Buka riwayat dan rincian biaya'),
          ),
        ],
        const SizedBox(height: 12),
        TaskSummaryCard(
          title: 'Keluhan kendaraan',
          icon: Icons.chat_bubble_outline,
          children: [Text(order.text('complaint'))],
        ),
        ExpansionTile(
          title: const Text('Checklist pekerjaan'),
          children: [
            for (final entry in order.checklist.entries)
              ListTile(
                leading: Icon(
                  entry.value
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: entry.value ? AppColors.success : AppColors.muted,
                ),
                title: Text(inspectionLabel(entry.key)),
                subtitle: Text(
                  entry.value ? 'Sudah diperiksa' : 'Belum diperiksa',
                ),
              ),
          ],
        ),
        ExpansionTile(
          title: const Text('Pemeriksaan & tindakan'),
          children: [
            Text('Diagnosis: ${order.text('diagnosis')}'),
            Text('Tindakan: ${order.text('actions')}'),
            Text('Catatan: ${order.text('notes')}'),
          ],
        ),
        ExpansionTile(
          title: const Text('Referensi penugasan'),
          children: [
            SelectableText('Service Order: ${order.id}'),
            if (order.technicianId != null)
              SelectableText('ID teknisi: ${order.technicianId}'),
            Text('Diperbarui: ${historyDate(order.date('updatedAt'))}'),
            Text('Revisi: ${order.revision}'),
          ],
        ),
        ExpansionTile(
          title: const Text('Pelacakan lengkap'),
          children: [ServiceTimeline(order: order)],
        ),
      ],
    );
  }
}

class AdminOrderParts extends ConsumerStatefulWidget {
  const AdminOrderParts({super.key, required this.orderId});
  final String orderId;
  @override
  ConsumerState<AdminOrderParts> createState() => _AdminPartsState();
}

class _AdminPartsState extends ConsumerState<AdminOrderParts> {
  final cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  Widget build(BuildContext context) {
    final provider = orderInventoryProvider((
      cursor: cursors.last,
      orderId: widget.orderId,
      requests: false,
    ));
    return TaskSummaryCard(
      title: 'Sparepart',
      icon: Icons.inventory_2_outlined,
      children: [
        ref
            .watch(provider)
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) =>
                  RetryLoad(onRetry: () => ref.invalidate(provider)),
              data: (page) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page.items.isEmpty)
                    const Text('Belum ada pemakaian sparepart.'),
                  for (final row in page.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row['name']} (${row['sku']})',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${row['kind'] == 'reversal' ? 'Dikembalikan' : 'Dipakai'}: ${row['quantity']} ${row['unit']}',
                          ),
                          Text(
                            '${rupiah(row['sellPrice'] as int)} / ${row['unit']}',
                          ),
                        ],
                      ),
                    ),
                  if (page.hasMore || cursors.length > 1)
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
    );
  }
}

class AdminOrderTimeline extends StatelessWidget {
  const AdminOrderTimeline({super.key, required this.order});
  final ServiceOrder order;
  @override
  Widget build(BuildContext context) {
    final current = switch (order.status) {
      ServiceOrderStatus.queued => 0,
      ServiceOrderStatus.assigned => 1,
      ServiceOrderStatus.completed => 3,
      ServiceOrderStatus.cancelled =>
        order.date('startedAt') != null
            ? 2
            : order.technicianId != null
            ? 1
            : 0,
      _ => 2,
    };
    const labels = ['Antrean', 'Ditugaskan', 'Dikerjakan', 'Selesai'];
    final stopped = order.status == ServiceOrderStatus.cancelled;
    Widget marker(int i) => Icon(
      stopped && i == current
          ? Icons.cancel_outlined
          : i < current || current == 3
          ? Icons.check_circle
          : i == current
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked,
      size: 25,
      color: stopped && i == current
          ? AppColors.danger
          : i < current || current == 3
          ? AppColors.success
          : i == current
          ? AppColors.secondary
          : AppColors.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Progress / Status Pengerjaan',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (MediaQuery.textScalerOf(context).scale(1) > 1.3)
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  marker(i),
                  const SizedBox(width: 12),
                  Expanded(child: Text(labels[i])),
                ],
              ),
            )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 2,
                              color: i == 0
                                  ? Colors.transparent
                                  : i <= current
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                          marker(i),
                          Expanded(
                            child: Divider(
                              thickness: 2,
                              color: i == labels.length - 1
                                  ? Colors.transparent
                                  : i < current
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if ([
          ServiceOrderStatus.paused,
          ServiceOrderStatus.awaitingApproval,
          ServiceOrderStatus.cancelled,
        ].contains(order.status))
          Text('Status: ${order.status.label}'),
      ],
    );
  }
}
