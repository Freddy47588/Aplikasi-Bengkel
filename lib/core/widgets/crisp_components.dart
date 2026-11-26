import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

/// Monospace Indonesian license plate pill.
class IndonesianPlateBadge extends StatelessWidget {
  const IndonesianPlateBadge({
    super.key,
    required this.plate,
    this.dark = false,
  });

  final String plate;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.30)
              : AppColors.primary,
          width: dark ? 1 : 1.5,
        ),
      ),
      child: Text(
        plate,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: dark ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }
}

/// High-contrast Midnight Carbon card with subtle orange ambient highlight.
class CarbonSpotlightCard extends StatelessWidget {
  const CarbonSpotlightCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.carbonElevated, Color(0xFF0D1017)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -28,
            child: IgnorePointer(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.24),
                      AppColors.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Universal motorcycle or car vehicle icon with automatic kind fallback.
class UniversalVehicleThumb extends StatelessWidget {
  const UniversalVehicleThumb({
    super.key,
    this.kind,
    this.vehicleName,
    this.size = 56,
    this.darkSurface = false,
  });

  final String? kind;
  final String? vehicleName;
  final double size;
  final bool darkSurface;

  static const _motorKeywords = [
    'vario',
    'beat',
    'nmax',
    'scoopy',
    'pcx',
    'mio',
    'motor',
    'supra',
    'vespa',
    'aerox',
    'lexi',
    'cbr',
    'ninja',
    'vixion',
    'klx',
    'trail',
    'satria',
    'jupiter',
    'revo',
    'genio',
    'adv',
    'fazzio',
    'filano',
    'crf',
    'rx',
  ];

  bool get _isMotorcycle {
    if (kind == 'motorcycle') return true;
    if (kind == 'car') return false;
    final lower = (vehicleName ?? '').toLowerCase();
    return _motorKeywords.any(lower.contains);
  }

  @override
  Widget build(BuildContext context) {
    final asset = _isMotorcycle
        ? 'assets/illustrations/vehicle_motor.png'
        : 'assets/illustrations/vehicle_car.png';
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: darkSurface ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular((size * 0.26).clamp(12, 18)),
        border: darkSurface ? null : Border.all(color: AppColors.border),
      ),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        semanticLabel: _isMotorcycle ? 'Ikon sepeda motor' : 'Ikon mobil',
      ),
    );
  }
}

/// Segmented visual progress bar for workshop service tracking.
class ServiceProgressStrip extends StatelessWidget {
  const ServiceProgressStrip({
    super.key,
    required this.activeStep,
    required this.labels,
    this.dark = true,
  });

  final int activeStep;
  final List<String> labels;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final count = labels.isEmpty ? 4 : labels.length;
    final clamped = activeStep.clamp(0, count);
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: i < clamped
                        ? AppColors.secondary
                        : dark
                        ? Colors.white.withValues(alpha: 0.16)
                        : AppColors.border,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (labels.isNotEmpty) ...[
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.3;
              if (narrow) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      _StepLabelText(
                        label: labels[i],
                        active: i == clamped - 1,
                        done: i < clamped - 1,
                        dark: dark,
                        style: labelStyle,
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Align(
                        alignment: i == 0
                            ? Alignment.centerLeft
                            : i == labels.length - 1
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: _StepLabelText(
                          label: labels[i],
                          active: i == clamped - 1,
                          done: i < clamped - 1,
                          dark: dark,
                          style: labelStyle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _StepLabelText extends StatelessWidget {
  const _StepLabelText({
    required this.label,
    required this.active,
    required this.done,
    required this.dark,
    required this.style,
  });

  final String label;
  final bool active;
  final bool done;
  final bool dark;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (dark ? AppColors.accentLight : AppColors.secondary)
        : done
        ? (dark ? Colors.white : AppColors.primary)
        : (dark ? Colors.white.withValues(alpha: 0.55) : AppColors.muted);

    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style?.copyWith(
        color: color,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

/// Pill segmented tab control that wraps cleanly at narrow widths/200% text.
class WorkshopSegmentedTabs<T> extends StatelessWidget {
  const WorkshopSegmentedTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < 280 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.3;
          if (stacked) {
            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final item in items)
                  _SegmentButton(
                    label: item.$2,
                    active: item.$1 == selected,
                    onTap: () => onSelected(item.$1),
                  ),
              ],
            );
          }
          return Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _SegmentButton(
                    label: item.$2,
                    active: item.$1 == selected,
                    onTap: () => onSelected(item.$1),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.onMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum QuickServiceKind { periodic, oil, brake, electric }

/// Precision duotone vector icon for customer quick-service categories.
class QuickServiceIcon extends StatelessWidget {
  const QuickServiceIcon(this.kind, {super.key, this.size = 26});

  final QuickServiceKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _QuickServicePainter(kind)),
      ),
    );
  }
}

class _QuickServicePainter extends CustomPainter {
  const _QuickServicePainter(this.kind);
  final QuickServiceKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final darkStroke = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final darkFill = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final orangeStroke = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.3 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final orangeFill = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    final orangeTint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    switch (kind) {
      case QuickServiceKind.periodic:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(12 * s, 14 * s), radius: 8.5 * s),
          math.pi * 0.9,
          math.pi * 1.2,
          false,
          darkStroke,
        );
        canvas.drawLine(
          Offset(12 * s, 14 * s),
          Offset(16.4 * s, 9.6 * s),
          orangeStroke,
        );
        canvas.drawCircle(Offset(12 * s, 14 * s), 2.1 * s, orangeFill);
        canvas.drawLine(
          Offset(7 * s, 18.8 * s),
          Offset(17 * s, 18.8 * s),
          Paint()
            ..color = AppColors.primary.withValues(alpha: 0.25)
            ..strokeWidth = 2.0 * s
            ..strokeCap = StrokeCap.round,
        );
      case QuickServiceKind.oil:
        final drop = Path()
          ..moveTo(12 * s, 3.2 * s)
          ..cubicTo(9 * s, 7 * s, 6 * s, 10.6 * s, 6 * s, 14.3 * s)
          ..arcToPoint(
            Offset(18 * s, 14.3 * s),
            radius: Radius.circular(6 * s),
            clockwise: false,
          )
          ..cubicTo(18 * s, 10.6 * s, 15 * s, 7 * s, 12 * s, 3.2 * s)
          ..close();
        canvas.drawPath(drop, orangeTint);
        canvas.drawPath(drop, darkStroke);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(12 * s, 14.8 * s), radius: 2.5 * s),
          math.pi * 0.5,
          math.pi * 0.55,
          false,
          orangeStroke,
        );
      case QuickServiceKind.brake:
        canvas.drawCircle(Offset(12 * s, 12 * s), 9 * s, darkStroke);
        canvas.drawCircle(Offset(12 * s, 12 * s), 3.1 * s, darkFill);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(12 * s, 12 * s), radius: 7.4 * s),
          -math.pi * 0.35,
          math.pi * 0.42,
          false,
          orangeStroke,
        );
        for (final offset in [
          Offset(12 * s, 6.2 * s),
          Offset(6.2 * s, 12 * s),
          Offset(12 * s, 17.8 * s),
        ]) {
          canvas.drawCircle(offset, 1.0 * s, darkFill);
        }
      case QuickServiceKind.electric:
        final bolt = Path()
          ..moveTo(13.2 * s, 2.5 * s)
          ..lineTo(5 * s, 13.5 * s)
          ..lineTo(11.2 * s, 13.5 * s)
          ..lineTo(10.2 * s, 21.5 * s)
          ..lineTo(19 * s, 10.5 * s)
          ..lineTo(12.8 * s, 10.5 * s)
          ..close();
        canvas.drawPath(bolt, orangeTint);
        canvas.drawPath(bolt, darkStroke);
        canvas.drawLine(
          Offset(11.2 * s, 13.5 * s),
          Offset(16.6 * s, 13.5 * s),
          orangeStroke,
        );
    }
  }

  @override
  bool shouldRepaint(_QuickServicePainter oldDelegate) =>
      oldDelegate.kind != kind;
}

/// Shared Customer section switcher (`Progres`, `Riwayat`, `Invoice`).
class CustomerFlowTabs extends StatelessWidget {
  const CustomerFlowTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return WorkshopSegmentedTabs<String>(
      items: const [
        ('orders', 'Progres'),
        ('history', 'Riwayat'),
        ('invoices', 'Invoice'),
      ],
      selected: selected,
      onSelected: onSelected,
    );
  }
}

/// Shared Admin section switcher (`Booking`, `Service Order`, `Teknisi`).
class AdminFlowTabs extends StatelessWidget {
  const AdminFlowTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return WorkshopSegmentedTabs<String>(
      items: const [
        ('bookings', 'Booking'),
        ('orders', 'Service Order'),
        ('technicians', 'Teknisi'),
      ],
      selected: selected,
      onSelected: onSelected,
    );
  }
}
