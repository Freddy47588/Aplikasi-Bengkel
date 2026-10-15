import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import 'firebase_providers.dart';

class WorkshopService {
  const WorkshopService(this.id, this.name);
  final String id;
  final String name;
}

abstract class ServiceRepository {
  Stream<List<WorkshopService>> watch();
}

class FirestoreServiceRepository implements ServiceRepository {
  FirestoreServiceRepository(this.db);
  final FirebaseFirestore db;
  @override
  Stream<List<WorkshopService>> watch() => db
      .collection('services')
      .where('active', isEqualTo: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => WorkshopService(d.id, d['name'] as String))
            .toList(),
      );
}

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => FirestoreServiceRepository(ref.watch(firestoreProvider)),
);
final servicesProvider = StreamProvider<List<WorkshopService>>((ref) {
  if (!ref.watch(authSessionProvider).isAuthenticated) return Stream.value([]);
  return ref.watch(serviceRepositoryProvider).watch();
});
