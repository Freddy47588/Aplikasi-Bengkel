import 'package:flutter/material.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  stage.index <= tracking.stage.index
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: stage.index <= tracking.stage.index
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${stage.index + 1}. ${labels[stage.index]}'),
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
