import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import 'status_chip.dart';
import 'workshop_art.dart';
export 'workshop_art.dart';
export 'session_splash.dart';

Future<bool> confirmWorkshopAction(
  BuildContext context,
  String message, {
  String title = 'Konfirmasi tindakan',
  String confirmLabel = 'Ya, sudah diperiksa',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ==
    true;

class WorkshopBody extends StatelessWidget {
  const WorkshopBody({super.key, required this.child, this.showWave = false});
  final Widget child;
  final bool showWave;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.pageWidth),
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: child,
              ),
            ),
            if (showWave && MediaQuery.viewInsetsOf(context).bottom == 0)
              const WorkshopWave(),
          ],
        ),
      ),
    ),
  );
}

/// Companion links explain the destinations grouped under Bengkel / Servis.
class WorkspaceLinks extends StatelessWidget {
  const WorkspaceLinks({super.key, required this.role});
  final String role;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final link in <(String, String, IconData)>[
        ('Progres servis', 'orders', Icons.car_repair_outlined),
        if (role == 'admin')
          ('Inventory', 'inventory', Icons.inventory_2_outlined),
        if (role != 'technician')
          ('Invoice & laporan', 'invoices', Icons.receipt_long_outlined),
        ('Riwayat', 'history', Icons.history),
      ])
        OutlinedButton.icon(
          onPressed: () => context.go('/$role/${link.$2}'),
          icon: Icon(link.$3),
          label: Text(link.$1),
        ),
    ],
  );
}

/// All children keep natural height, including at enlarged text sizes.
class AdaptiveCards extends StatelessWidget {
  const AdaptiveCards({super.key, required this.children, this.minWidth = 240});
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = (box.maxWidth / minWidth).floor().clamp(1, 3);
      final width = (box.maxWidth - AppSpace.md * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpace.md,
        runSpacing: AppSpace.md,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class BrandEmblem extends StatelessWidget {
  const BrandEmblem({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/branding/emblem-mockup.png',
    width: size,
    height: size,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
    semanticLabel: 'Logo roda gigi dan kunci pas BengkelKu',
  );
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
    child: Column(
      children: [
        const BrandEmblem(size: 72),
        const SizedBox(height: AppSpace.sm),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Bengkel'),
              TextSpan(
                text: 'Ku',
                style: TextStyle(color: AppColors.secondary),
              ),
            ],
          ),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpace.xs),
        const Text(
          'Aplikasi Manajemen Bengkel',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.primary),
        ),
      ],
    ),
  );
}

/// Status stays below the title so long identifiers and enlarged text wrap.
class WorkshopRecordCard extends StatelessWidget {
  const WorkshopRecordCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.status,
    this.onTap,
    this.enabled = true,
  });
  final String title, description;
  final IconData icon;
  final Widget? status;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpace.md),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.sm),
              decoration: BoxDecoration(
                color: AppColors.blueSurface,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpace.xs),
                  Text(description),
                  if (status != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    status!,
                  ],
                ],
              ),
            ),
            if (onTap != null && enabled) ...[
              const SizedBox(width: AppSpace.xs),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ],
        ),
      ),
    ),
  );
}

class PageIntro extends StatelessWidget {
  const PageIntro({
    super.key,
    required this.title,
    required this.description,
    this.art,
    this.showTitle = true,
  });
  final String title, description;
  final WorkshopArt? art;
  final bool showTitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (art != null &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
          WorkshopIllustration(art!, height: 104),
          const SizedBox(height: AppSpace.md),
        ],
        if (showTitle) ...[
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(
          description,
          textAlign: showTitle ? TextAlign.start : TextAlign.center,
        ),
      ],
    ),
  );
}

class WorkshopHero extends StatelessWidget {
  const WorkshopHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.art,
    this.compact = false,
  });
  final String eyebrow, title, description;
  final WorkshopArt? art;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.xl),
    decoration: BoxDecoration(
      color: AppColors.blueSurface,
      borderRadius: BorderRadius.circular(AppRadius.hero),
      border: Border.all(color: AppColors.blueBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const BrandEmblem(size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eyebrow,
                style: const TextStyle(
                  color: AppColors.onMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.primary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (compact &&
                art != null &&
                MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: WorkshopIllustration(art!, height: 96),
              ),
            ],
          ],
        ),
        if (!compact && art != null) ...[
          const SizedBox(height: AppSpace.sm),
          WorkshopIllustration(art!, height: 112),
        ],
      ],
    ),
  );
}

class ContentSection extends StatelessWidget {
  const ContentSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class LoadError extends StatelessWidget {
  const LoadError({
    super.key,
    required this.onRetry,
    this.message = 'Data belum dapat dimuat. Periksa koneksi dan coba lagi.',
  });
  final VoidCallback onRetry;
  final String message;
  @override
  Widget build(BuildContext context) => ContentSection(
    title: 'Perlu dicoba lagi',
    children: [
      const Icon(Icons.cloud_off_outlined, color: AppColors.muted),
      const SizedBox(height: 8),
      Text(message),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Coba lagi'),
      ),
    ],
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(semanticsLabel: 'Memuat data bengkel'),
          SizedBox(height: 12),
          Text('Memuat data bengkel…'),
        ],
      ),
    ),
  );
}

String paymentStatusLabel(String status) => switch (status) {
  'paid' => 'Lunas',
  'partial' => 'Dibayar sebagian',
  'unpaid' => 'Belum dibayar',
  'void' => 'Dibatalkan',
  'refunded' => 'Dikembalikan',
  _ => status,
};

class PaymentBadge extends StatelessWidget {
  const PaymentBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: StatusChip(
      label: paymentStatusLabel(status),
      tone: status == 'paid'
          ? StatusChipTone.success
          : status == 'partial'
          ? StatusChipTone.info
          : ['void', 'refunded'].contains(status)
          ? StatusChipTone.neutral
          : StatusChipTone.warning,
    ),
  );
}
