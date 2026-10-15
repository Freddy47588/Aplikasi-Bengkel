import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceOrderStatus {
  queued('Antrean'),
  assigned('Ditugaskan'),
  inProgress('Dikerjakan'),
  paused('Dijeda'),
  awaitingApproval('Menunggu persetujuan admin'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  const ServiceOrderStatus(this.label);
  final String label;
  bool get terminal => this == completed || this == cancelled;
  bool canTransitionTo(ServiceOrderStatus next, {required bool admin}) => admin
      ? (!terminal && next == cancelled) ||
            (this == awaitingApproval &&
                (next == completed || next == assigned))
      : ((this == assigned || this == paused) && next == inProgress) ||
            (this == inProgress &&
                (next == paused || next == awaitingApproval));
}

class Technician {
  Technician(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  String get name => data['name'] as String;
  String get specialization => data['specialization'] as String;
  bool get active => data['active'] == true;
  bool get available => data['available'] == true;
  String? get currentOrderId => data['currentOrderId'] as String?;
  bool get assignable => active && available && currentOrderId == null;
}

class ServiceOrder {
  ServiceOrder(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
  ServiceOrderStatus get status =>
      ServiceOrderStatus.values.byName(data['status'] as String);
  int get revision => data['revision'] as int;
  String? get technicianId => data['technicianId'] as String?;
  String text(String key) => data[key] as String? ?? '';
  Map<String, bool> get checklist =>
      Map<String, bool>.from(data['checklist'] as Map);
  DateTime? date(String key) => (data[key] as Timestamp?)?.toDate();
}

const inspectionKeys = ['vehicleChecked', 'safetyChecked', 'workChecked'];

class RecordPage<T> {
  const RecordPage(this.items, this.cursor, this.hasMore);
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}
