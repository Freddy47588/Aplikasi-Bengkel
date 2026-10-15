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
  const Vehicle(this.id, this.name, this.plate);
  final String id;
  final String name;
  final String plate;
}

const demoVehicles = [
  Vehicle('brio', 'Honda Brio RS', 'B 1234 XYZ'),
  Vehicle('avanza', 'Toyota Avanza', 'N 1234 AB'),
];
const serviceTypes = [
  'Service Berkala',
  'Ganti Oli',
  'Tune Up',
  'Pemeriksaan Rem',
];
const serviceHours = [9, 10, 11, 13, 14, 15, 16];

class BookingDraft {
  const BookingDraft({
    required this.vehicleId,
    required this.service,
    required this.scheduledAt,
    required this.complaint,
  });
  final String vehicleId;
  final String service;
  final DateTime scheduledAt;
  final String complaint;
  String? validate(DateTime now) {
    if (!demoVehicles.any((v) => v.id == vehicleId)) {
      return 'Pilih kendaraan yang valid.';
    }
    if (!serviceTypes.contains(service)) return 'Pilih layanan yang valid.';
    if (!scheduledAt.isAfter(now) ||
        scheduledAt.isAfter(now.add(const Duration(days: 90)))) {
      return 'Jadwal harus di masa depan, maksimal 90 hari.';
    }
    if (!serviceHours.contains(scheduledAt.hour) ||
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
  Vehicle get vehicle =>
      demoVehicles.firstWhere((v) => v.id == draft.vehicleId);
  Booking withStatus(BookingStatus value) =>
      Booking(id: id, customerId: customerId, draft: draft, status: value);
}
