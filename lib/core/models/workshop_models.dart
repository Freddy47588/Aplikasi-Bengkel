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
