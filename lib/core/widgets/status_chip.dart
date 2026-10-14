import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum StatusChipTone { success, warning, neutral, danger, info }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusChipTone.neutral,
  });

  final String label;
  final StatusChipTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      StatusChipTone.success => AppColors.success,
      StatusChipTone.warning => AppColors.warning,
      StatusChipTone.danger => AppColors.danger,
      StatusChipTone.info => AppColors.secondary,
      StatusChipTone.neutral => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
