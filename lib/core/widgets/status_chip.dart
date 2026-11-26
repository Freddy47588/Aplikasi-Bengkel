import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

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
    final (fg, bg) = switch (tone) {
      StatusChipTone.success => (AppColors.success, const Color(0xFFECFDF5)),
      StatusChipTone.warning => (AppColors.warning, const Color(0xFFFFFBEB)),
      StatusChipTone.danger => (AppColors.danger, const Color(0xFFFEF2F2)),
      StatusChipTone.info => (AppColors.secondary, AppColors.accentSoft),
      StatusChipTone.neutral => (AppColors.onMuted, AppColors.background),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
