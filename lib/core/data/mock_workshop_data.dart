import '../models/workshop_models.dart';

class MockWorkshopData {
  const MockWorkshopData._();

  static const List<VehicleBooking> bookings = [
    VehicleBooking(
      id: 'BKG-001',
      customerName: 'Achmad',
      vehicleName: 'Honda Brio RS',
      vehiclePlate: 'B 1234 XYZ',
      serviceType: 'Service Berkala',
      date: 'Jumat, 25 Oktober 2026',
      time: '09:30 - 11:00',
      status: 'Dikonfirmasi',
    ),
    VehicleBooking(
      id: 'BKG-002',
      customerName: 'Nadia',
      vehicleName: 'Toyota Avanza',
      vehiclePlate: 'N 1234 AB',
      serviceType: 'Ganti Oli',
      date: 'Sabtu, 26 Oktober 2026',
      time: '10:00 - 10:45',
      status: 'Menunggu',
    ),
  ];

  static const List<ServiceJob> jobs = [
    ServiceJob(
      id: 'SO-2026-001',
      vehicleName: 'Honda Brio',
      plateNumber: 'B 1234 XYZ',
      assignee: 'Teknisi A',
      startTime: '09:00',
      status: 'Menunggu',
    ),
    ServiceJob(
      id: 'SO-2026-002',
      vehicleName: 'Toyota Avanza',
      plateNumber: 'N 1234 AB',
      assignee: 'Teknisi B',
      startTime: '10:30',
      status: 'Sedang Dikerjakan',
    ),
    ServiceJob(
      id: 'SO-2026-003',
      vehicleName: 'Daihatsu Xenia',
      plateNumber: 'L 9876 CD',
      assignee: 'Teknisi C',
      startTime: '11:15',
      status: 'Selesai',
    ),
  ];
}
