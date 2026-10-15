import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../models/booking.dart';
import 'firebase_providers.dart';

String normalizePlate(String value) {
  final compact = value.toUpperCase().replaceAll(RegExp(r'\s+'), '');
  final match = RegExp(
    r'^([A-Z]{1,2})([0-9]{1,4})([A-Z]{0,3})$',
  ).firstMatch(compact);
  if (match == null) throw ArgumentError('Plat harus seperti B 1234 XYZ.');
  return '${match[1]} ${match[2]}${match[3]!.isEmpty ? '' : ' ${match[3]}'}';
}

abstract class VehicleRepository {
  Stream<List<Vehicle>> watch(String uid);
  Future<void> save(String uid, String name, String plate, {String? id});
  Future<void> delete(String uid, String id);
}

class FirestoreVehicleRepository implements VehicleRepository {
  FirestoreVehicleRepository(this.db);
  final FirebaseFirestore db;
  @override
  Stream<List<Vehicle>> watch(String uid) => db
      .collection('vehicles')
      .where('ownerId', isEqualTo: uid)
      .where('active', isEqualTo: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => s.docs
            .map(
              (d) => Vehicle(
                d.id,
                d['name'] as String,
                d['plate'] as String,
                ownerId: d['ownerId'] as String,
              ),
            )
            .toList(),
      );
  @override
  Future<void> save(String uid, String name, String plate, {String? id}) async {
    if (name.trim().isEmpty || name.trim().length > 80) {
      throw ArgumentError('Nama kendaraan harus 1–80 karakter.');
    }
    final normalized = normalizePlate(plate);
    final doc = db.collection('vehicles').doc(id);
    if (id == null) {
      await doc.set({
        'ownerId': uid,
        'name': name.trim(),
        'plate': normalized,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await db.runTransaction((tx) async {
      final before = await tx.get(doc);
      if ((!before.exists ||
          before['ownerId'] != uid ||
          before['active'] != true)) {
        throw StateError('Kendaraan bukan milik Anda atau sudah dihapus.');
      }
      tx.set(doc, {
        'ownerId': uid,
        'name': name.trim(),
        'plate': normalized,
        'active': true,
        'createdAt': before.exists
            ? before['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> delete(String uid, String id) => db.runTransaction((tx) async {
    final doc = db.collection('vehicles').doc(id);
    final before = await tx.get(doc);
    if (!before.exists || before['ownerId'] != uid) {
      throw StateError('Kendaraan bukan milik Anda.');
    }
    // Keep booking snapshots/history valid after deleting a vehicle.
    tx.update(doc, {
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => FirestoreVehicleRepository(ref.watch(firestoreProvider)),
);
final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final session = ref.watch(authSessionProvider);
  if (!session.isAuthenticated || session.role?.name != 'customer') {
    return Stream.value([]);
  }
  return ref.watch(vehicleRepositoryProvider).watch(session.userId);
});
