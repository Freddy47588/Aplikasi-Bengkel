import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/service_history.dart';
import '../../../core/models/service_order.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';

String technicianStatusLabel(ServiceOrderStatus status) => switch (status) {
  ServiceOrderStatus.assigned => 'Menunggu',
  ServiceOrderStatus.inProgress => 'Diproses',
  _ => status.label,
};

StatusChipTone technicianStatusTone(ServiceOrderStatus status) =>
    switch (status) {
      ServiceOrderStatus.completed => StatusChipTone.success,
      ServiceOrderStatus.cancelled => StatusChipTone.neutral,
      ServiceOrderStatus.inProgress => StatusChipTone.info,
      _ => StatusChipTone.warning,
    };

class TechnicianStatus extends StatelessWidget {
  const TechnicianStatus({super.key, required this.status});
  final ServiceOrderStatus status;
  @override
  Widget build(BuildContext context) => StatusChip(
    label: technicianStatusLabel(status),
    tone: technicianStatusTone(status),
  );
}

class TechnicianTaskCard extends StatelessWidget {
  const TechnicianTaskCard({
    super.key,
    required this.order,
    required this.onTap,
  });
  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.blueBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(
                Icons.directions_car_outlined,
                size: 30,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechnicianOrderHeading(order: order),
                  const SizedBox(height: 5),
                  Text(
                    '${order.text('vehiclePlate')} · ${order.text('vehicleName')}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.build_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.text('serviceName'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Icon(Icons.chevron_right, size: 22),
            ),
          ],
        ),
      ),
    ),
  );
}

class TechnicianOrderHeading extends StatelessWidget {
  const TechnicianOrderHeading({super.key, required this.order});
  final ServiceOrder order;
  @override
  Widget build(BuildContext context) {
    final title = Text(
      order.id,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
      ),
    );
    final badge = TechnicianStatus(status: order.status);
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
        order.status == ServiceOrderStatus.awaitingApproval) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 6), badge],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 8),
        Flexible(child: badge),
      ],
    );
  }
}

class TechnicianTaskIntro extends StatelessWidget {
  const TechnicianTaskIntro({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
        const WorkshopIllustration(WorkshopArt.checklist, height: 128),
        const SizedBox(height: 12),
      ],
      const Text(
        'Daftar tugas servis milik Anda.\nPantau status dan selesaikan pekerjaan.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
    ],
  );
}

class TechnicianInformation extends StatelessWidget {
  const TechnicianInformation({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.blueBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppColors.secondary, size: 25),
                const SizedBox(width: 12),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class TechnicianTimeline extends StatelessWidget {
  const TechnicianTimeline({super.key, required this.order});
  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final tracking = ServiceTracking.from(BookingStatus.confirmed, order);
    final current = switch (tracking.stage) {
      TrackingStage.inProgress => 1,
      TrackingStage.completed => 2,
      _ => 0,
    };
    const labels = ['Menunggu', 'Diproses', 'Selesai'];
    Widget marker(int index) => Icon(
      tracking.stopped && index == current
          ? Icons.cancel_outlined
          : index < current || current == 2
          ? Icons.check_circle
          : index == current
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked,
      color: tracking.stopped && index == current
          ? AppColors.danger
          : index < current || current == 2
          ? AppColors.success
          : index == current
          ? AppColors.secondary
          : AppColors.muted,
      size: 26,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Progress Pengerjaan',
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
                              color: i == 2
                                  ? Colors.transparent
                                  : i < current
                                  ? AppColors.success
                                  : AppColors.border,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
        ].contains(order.status)) ...[
          const SizedBox(height: 8),
          Text(
            tracking.stopped
                ? 'Servis dibatalkan; proses tidak dilanjutkan.'
                : 'Status: ${order.status.label}',
          ),
        ],
      ],
    );
  }
}

class TechnicianTaskDetail extends StatelessWidget {
  const TechnicianTaskDetail({
    super.key,
    required this.order,
    required this.busy,
    required this.onTransition,
    required this.onChecklist,
    required this.onParts,
    required this.onHistory,
    this.onCompletion,
  });
  final ServiceOrder order;
  final bool busy;
  final Future<void> Function(ServiceOrderStatus) onTransition;
  final VoidCallback onChecklist, onParts, onHistory;
  final VoidCallback? onCompletion;

  @override
  Widget build(BuildContext context) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    children: [
      Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.blueBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 28,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(child: TechnicianOrderHeading(order: order)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      TechnicianInformation(
        title: 'Informasi Kendaraan',
        icon: Icons.directions_car_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.text('vehiclePlate'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(order.text('vehicleName')),
          ],
        ),
      ),
      TechnicianInformation(
        title: 'Jenis Servis',
        icon: Icons.build_outlined,
        child: Text(order.text('serviceName')),
      ),
      TechnicianInformation(
        title: 'Jadwal Pengerjaan',
        icon: Icons.calendar_today_outlined,
        child: Text(historyDate(order.date('scheduledAt'))),
      ),
      TechnicianInformation(
        title: 'Catatan Keluhan',
        icon: Icons.chat_bubble_outline,
        child: Text(order.text('complaint')),
      ),
      TechnicianTimeline(order: order),
      const SizedBox(height: 20),
      if (busy) const LinearProgressIndicator(),
      for (final next in ServiceOrderStatus.values.where(
        (s) => order.status.canTransitionTo(s, admin: false),
      )) ...[
        if (next == ServiceOrderStatus.inProgress)
          FilledButton.icon(
            onPressed: busy ? null : () => onTransition(next),
            icon: const Icon(Icons.play_arrow_outlined),
            label: Text(
              order.status == ServiceOrderStatus.paused
                  ? 'Lanjutkan pengerjaan'
                  : 'Mulai pengerjaan',
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: busy ? null : () => onTransition(next),
            icon: Icon(
              next == ServiceOrderStatus.paused ? Icons.pause : Icons.check,
            ),
            label: Text(
              next == ServiceOrderStatus.paused
                  ? 'Jeda pengerjaan'
                  : 'Ajukan selesai',
            ),
          ),
        const SizedBox(height: 8),
      ],
      if ([
        ServiceOrderStatus.inProgress,
        ServiceOrderStatus.paused,
      ].contains(order.status)) ...[
        OutlinedButton.icon(
          onPressed: busy ? null : onChecklist,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Checklist dan catatan kerja'),
        ),
        const SizedBox(height: 8),
      ],
      OutlinedButton.icon(
        onPressed: onParts,
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Sparepart dan permintaan'),
      ),
      if (order.status == ServiceOrderStatus.completed)
        TextButton(
          onPressed: onHistory,
          child: const Text('Buka riwayat dan rincian biaya'),
        ),
      if (onCompletion != null &&
          [
            ServiceOrderStatus.awaitingApproval,
            ServiceOrderStatus.completed,
          ].contains(order.status))
        OutlinedButton.icon(
          onPressed: onCompletion,
          icon: const Icon(Icons.task_alt),
          label: const Text('Ringkasan penyelesaian'),
        ),
      const SizedBox(height: 12),
      ExpansionTile(
        title: const Text('Checklist dan hasil pemeriksaan'),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (key, label) in [
            ('vehicleChecked', 'Kondisi kendaraan diperiksa'),
            ('safetyChecked', 'Keselamatan diperiksa'),
            ('workChecked', 'Hasil pekerjaan diperiksa'),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                order.checklist[key] == true
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
              ),
              title: Text(label),
              subtitle: Text(
                order.checklist[key] == true
                    ? 'Sudah diperiksa'
                    : 'Belum diperiksa',
              ),
            ),
          Text('Diagnosis: ${order.text('diagnosis')}'),
          const SizedBox(height: 8),
          Text('Tindakan: ${order.text('actions')}'),
          const SizedBox(height: 8),
          Text('Catatan: ${order.text('notes')}'),
        ],
      ),
      ExpansionTile(
        title: const Text('Referensi penugasan'),
        tilePadding: EdgeInsets.zero,
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText('Service Order: ${order.id}'),
          Text(
            'Teknisi: ${order.text('technicianName').isEmpty ? 'Nama belum tercatat' : order.text('technicianName')}',
          ),
          if (order.technicianId != null)
            SelectableText('ID teknisi: ${order.technicianId}'),
          Text('Diperbarui: ${historyDate(order.date('updatedAt'))}'),
          Text(
            'Biaya jasa: ${order.data['laborPrice'] == null ? 'Belum dicatat' : rupiah(order.data['laborPrice'] as int)}',
          ),
        ],
      ),
    ],
  );
}
