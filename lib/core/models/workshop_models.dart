class VehicleBooking {
  const VehicleBooking({
    required this.id,
    required this.customerName,
    required this.vehicleName,
    required this.vehiclePlate,
    required this.serviceType,
    required this.date,
    required this.time,
    required this.status,
  });

  final String id;
  final String customerName;
  final String vehicleName;
  final String vehiclePlate;
  final String serviceType;
  final String date;
  final String time;
  final String status;
}

class ServiceJob {
  const ServiceJob({
    required this.id,
    required this.vehicleName,
    required this.plateNumber,
    required this.assignee,
    required this.startTime,
    required this.status,
  });

  final String id;
  final String vehicleName;
  final String plateNumber;
  final String assignee;
  final String startTime;
  final String status;
}
