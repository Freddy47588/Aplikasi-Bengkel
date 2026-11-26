import 'package:bengkel_kendaraan/app/theme/app_colors.dart';
import 'package:bengkel_kendaraan/core/widgets/workshop_ui.dart';
import 'package:flutter/material.dart';

class AccountIntro extends StatelessWidget {
  const AccountIntro({
    super.key,
    required this.title,
    required this.description,
    this.eyebrow = 'BengkelKu',
  });

  final String title;
  final String description;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandEmblem(size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: text.labelLarge?.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Sistem Manajemen Bengkel',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: text.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: text.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class AccountNotice extends StatelessWidget {
  const AccountNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.tinted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final color = tinted ? AppColors.secondary : AppColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tinted ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: tinted ? AppColors.accentBorder : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tinted
                  ? AppColors.secondary.withValues(alpha: 0.14)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountProfileHeader extends StatelessWidget {
  const AccountProfileHeader({
    super.key,
    required this.label,
    required this.email,
    this.badge,
  });

  final String label;
  final String email;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final source = email.trim().isNotEmpty ? email.trim() : label.trim();
    final initials = source.isNotEmpty
        ? source.substring(0, 1).toUpperCase()
        : 'B';

    return CarbonSpotlightCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.45),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13.5,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 10),
                  badge!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
