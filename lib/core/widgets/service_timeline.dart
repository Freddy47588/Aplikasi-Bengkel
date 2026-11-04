import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';
import '../models/booking.dart';
import '../models/service_order.dart';
import '../models/service_history.dart';

class ServiceTimeline extends StatelessWidget {
  const ServiceTimeline({
    super.key,
    this.booking = BookingStatus.confirmed,
    this.order,
  });
  final BookingStatus booking;
  final ServiceOrder? order;
  @override
  Widget build(BuildContext context) {
    final tracking = ServiceTracking.from(booking, order);
    const labels = [
      'Menunggu',
      'Dikonfirmasi',
      'Ditugaskan',
      'Dikerjakan',
      'Selesai',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pelacakan: ${tracking.label}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        for (final stage in TrackingStage.values)
          Container(
            margin: const EdgeInsets.only(top: AppSpace.sm),
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: stage == tracking.stage ? AppColors.blueSurface : null,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                Icon(
                  stage == tracking.stage && tracking.stopped
                      ? Icons.cancel_outlined
                      : stage == tracking.stage &&
                            stage != TrackingStage.completed
                      ? Icons.radio_button_checked
                      : stage.index <= tracking.stage.index
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 24,
                  color: stage == tracking.stage && tracking.stopped
                      ? AppColors.danger
                      : stage == tracking.stage &&
                            stage != TrackingStage.completed
                      ? AppColors.secondary
                      : stage.index <= tracking.stage.index
                      ? AppColors.success
                      : AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stage == tracking.stage
                        ? '${stage.index + 1}. ${tracking.label}'
                        : '${stage.index + 1}. ${labels[stage.index]}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: stage == tracking.stage
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (tracking.stopped)
          const Text('Proses berhenti; tahap berikutnya tidak dilanjutkan.'),
      ],
    );
  }
}
