import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking.dart';
import 'service_order.dart';

/// A view of the canonical, immutable completed order; never a second input.
class HistoryFilter {
  const HistoryFilter({
    this.vehicleId = '',
    this.serviceId = '',
    this.from,
    this.until,
    this.cursor,
  });
  final String vehicleId, serviceId;

  /// Inclusive lower bound and exclusive upper bound, expressed as instants.
  final DateTime? from, until;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  @override
  bool operator ==(Object other) =>
      other is HistoryFilter &&
      vehicleId == other.vehicleId &&
      serviceId == other.serviceId &&
      from == other.from &&
      until == other.until &&
      cursor == other.cursor;
  @override
  int get hashCode => Object.hash(vehicleId, serviceId, from, until, cursor);
}

enum TrackingStage { pending, confirmed, assigned, inProgress, completed }

class ServiceTracking {
  const ServiceTracking(this.stage, this.label, {this.stopped = false});
  final TrackingStage stage;
  final String label;
  final bool stopped;
  factory ServiceTracking.from(BookingStatus booking, ServiceOrder? order) {
    if (booking == BookingStatus.rejected ||
        booking == BookingStatus.cancelled) {
      return ServiceTracking(
        TrackingStage.pending,
        booking.label,
        stopped: true,
      );
    }
    if (order == null) {
      return ServiceTracking(
        booking == BookingStatus.pending
            ? TrackingStage.pending
            : TrackingStage.confirmed,
        booking.label,
      );
    }
    return switch (order.status) {
      ServiceOrderStatus.queued => const ServiceTracking(
        TrackingStage.confirmed,
        'Menunggu penugasan',
      ),
      ServiceOrderStatus.assigned => const ServiceTracking(
        TrackingStage.assigned,
        'Ditugaskan',
      ),
      ServiceOrderStatus.inProgress => const ServiceTracking(
        TrackingStage.inProgress,
        'Dikerjakan',
      ),
      ServiceOrderStatus.paused => const ServiceTracking(
        TrackingStage.inProgress,
        'Dijeda',
      ),
      ServiceOrderStatus.awaitingApproval => const ServiceTracking(
        TrackingStage.inProgress,
        'Menunggu persetujuan admin',
      ),
      ServiceOrderStatus.completed => const ServiceTracking(
        TrackingStage.completed,
        'Selesai',
      ),
      ServiceOrderStatus.cancelled => ServiceTracking(
        order.date('startedAt') != null
            ? TrackingStage.inProgress
            : order.technicianId != null
            ? TrackingStage.assigned
            : TrackingStage.confirmed,
        'Servis dibatalkan',
        stopped: true,
      ),
    };
  }
}

class HistoryParts {
  const HistoryParts(this.lines, {this.fromCache = false});
  final List<Map<String, dynamic>> lines;
  final bool fromCache;
  int get subtotal => lines.fold(
    0,
    (total, line) =>
        total +
        (line['kind'] == 'reversal' ? -1 : 1) *
            (line['quantity'] as int) *
            (line['sellPrice'] as int),
  );
}

String rupiah(int value) =>
    'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

String historyDate(DateTime? value) {
  if (value == null) return 'Belum tersedia';
  final wib = value.toUtc().add(const Duration(hours: 7));
  return '${wib.day}/${wib.month}/${wib.year} '
      '${wib.hour.toString().padLeft(2, '0')}:${wib.minute.toString().padLeft(2, '0')} WIB';
}

DateTime wibDay(DateTime calendarDay) => DateTime.utc(
  calendarDay.year,
  calendarDay.month,
  calendarDay.day,
).subtract(const Duration(hours: 7));
