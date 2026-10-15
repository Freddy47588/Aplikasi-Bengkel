enum BookingStatus {
  pending('Menunggu'),
  confirmed('Dikonfirmasi'),
  rejected('Ditolak'),
  cancelled('Dibatalkan');

  const BookingStatus(this.label);
  final String label;
  bool get isActive => this == pending || this == confirmed;
}

class Vehicle {
  const Vehicle(this.id, this.name, this.plate, {this.ownerId = ''});
  final String id;
  final String name;
  final String plate;
  final String ownerId;
}

const serviceHours = [9, 10, 11, 13, 14, 15, 16];

class BookingDraft {
  const BookingDraft({
    required this.vehicleId,
    required this.service,
    required this.scheduledAt,
    required this.complaint,
    this.serviceId,
    this.vehicleName,
    this.vehiclePlate,
  });
  final String vehicleId;
  final String service;
  final DateTime scheduledAt;
  final String complaint;
  final String? serviceId;
  final String? vehicleName;
  final String? vehiclePlate;
  String? validate(DateTime now) {
    if (vehicleId.trim().isEmpty) {
      return 'Pilih kendaraan yang valid.';
    }
    if (service.trim().isEmpty) return 'Pilih layanan yang valid.';
    if (!scheduledAt.isAfter(now) ||
        scheduledAt.isAfter(now.add(const Duration(days: 90)))) {
      return 'Jadwal harus di masa depan, maksimal 90 hari.';
    }
    final workshopTime = scheduledAt.isUtc
        ? scheduledAt.add(const Duration(hours: 7))
        : scheduledAt;
    if (!serviceHours.contains(workshopTime.hour) ||
        scheduledAt.minute != 0 ||
        scheduledAt.second != 0) {
      return 'Pilih jam servis yang tersedia.';
    }
    if (complaint.trim().length < 5 || complaint.trim().length > 500) {
      return 'Keluhan harus 5–500 karakter.';
    }
    return null;
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.draft,
    this.status = BookingStatus.pending,
  });
  final String id;
  final String customerId;
  final BookingDraft draft;
  final BookingStatus status;
  Vehicle get vehicle => Vehicle(
    draft.vehicleId,
    draft.vehicleName ?? draft.vehicleId,
    draft.vehiclePlate ?? '',
    ownerId: customerId,
  );
  Booking withStatus(BookingStatus value) =>
      Booking(id: id, customerId: customerId, draft: draft, status: value);
}
