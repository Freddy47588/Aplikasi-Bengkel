import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/inventory.dart';
import '../../../core/models/service_history.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/workshop_ui.dart';

class InventoryIntro extends StatelessWidget {
  const InventoryIntro({
    super.key,
    required this.art,
    required this.description,
  });
  final WorkshopArt art;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
        WorkshopIllustration(art, height: 128),
        const SizedBox(height: 12),
      ],
      Text(description, textAlign: TextAlign.center),
      const SizedBox(height: 20),
    ],
  );
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.part});
  final Sparepart part;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: !part.active
        ? 'Nonaktif'
        : part.stock == 0
        ? 'Habis'
        : part.stock <= part.number('minimumStock')
        ? 'Minimum'
        : 'Aman',
    tone: !part.active
        ? StatusChipTone.neutral
        : part.stock == 0
        ? StatusChipTone.danger
        : part.stock <= part.number('minimumStock')
        ? StatusChipTone.warning
        : StatusChipTone.success,
  );
}

class InventoryPartCard extends StatelessWidget {
  const InventoryPartCard({super.key, required this.part, required this.onTap});
  final Sparepart part;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.blueBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.view_in_ar_outlined,
                color: AppColors.secondary,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.text('name'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Stok: ${part.stock} ${part.text('unit')}'),
                    if (largeText) ...[
                      const SizedBox(height: 6),
                      StockBadge(part: part),
                    ],
                  ],
                ),
              ),
              if (!largeText) ...[
                const SizedBox(width: 8),
                StockBadge(part: part),
              ],
              const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class StockInfoRow extends StatelessWidget {
  const StockInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
    this.color = AppColors.secondary,
  });
  final IconData icon;
  final String label, value;
  final Color color;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final labelWidget = Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
              final valueWidget =
                  badge ??
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.primary),
                  );
              if (MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
                  box.maxWidth < 230) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 6),
                    valueWidget,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: labelWidget),
                  const SizedBox(width: 12),
                  Flexible(child: valueWidget),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class StockMovementCard extends StatelessWidget {
  const StockMovementCard({super.key, required this.movement, this.onReverse});
  final StockMovement movement;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final m = movement;
    final (label, tone, color, icon) = switch (m.kind) {
      MovementKind.receipt => (
        'Masuk',
        StatusChipTone.success,
        AppColors.success,
        Icons.arrow_downward,
      ),
      MovementKind.usage => (
        'Keluar',
        StatusChipTone.danger,
        AppColors.danger,
        Icons.arrow_upward,
      ),
      MovementKind.adjustment => (
        'Koreksi',
        StatusChipTone.info,
        AppColors.info,
        Icons.sync,
      ),
      MovementKind.reversal => (
        'Reversal',
        StatusChipTone.neutral,
        AppColors.onMuted,
        Icons.undo,
      ),
    };
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.blueBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        trailing: const Icon(
          Icons.expand_more,
          size: 18,
          semanticLabel: 'Detail transaksi',
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusChip(label: label, tone: tone),
                            const SizedBox(height: 3),
                            Text(
                              '${m.delta > 0 ? '+' : ''}${m.delta} ${m.data['unit']}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      if (!largeText) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            historyDate(
                              (m.data['createdAt'] as Timestamp?)?.toDate(),
                            ),
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m.sku} · ${m.data['reason']}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                  if (largeText)
                    Text(
                      historyDate(
                        (m.data['createdAt'] as Timestamp?)?.toDate(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Text(
            'Saldo: ${m.data['balanceBefore']} → ${m.data['balanceAfter']} ${m.data['unit']}',
          ),
          Text('Actor: ${m.data['actorId']}'),
          if (m.data['serviceOrderId'] != null)
            Text('SO: ${m.data['serviceOrderId']}'),
          if (m.data['reversalOf'] != null)
            Text('Reversal: ${m.data['reversalOf']}'),
          if (onReverse != null)
            TextButton.icon(
              onPressed: onReverse,
              icon: const Icon(Icons.undo),
              label: const Text('Reversal penuh'),
            ),
        ],
      ),
    );
  }
}
