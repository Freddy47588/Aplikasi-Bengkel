import '../models/workshop_models.dart';

class MockWorkshopData {
  const MockWorkshopData._();

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
