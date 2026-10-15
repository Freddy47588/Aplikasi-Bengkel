import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/user_role.dart';
import '../../../core/data/firebase_providers.dart';

class AuthSession {
  const AuthSession({
    this.uid,
    this.email,
    this.role,
    this.loading = false,
    this.verified = false,
    this.active = true,
    this.error,
  });
  final String? uid;
  final String? email;
  final UserRole? role;
  final bool loading;
  final bool verified;
  final bool active;
  final String? error;
  String get userId => uid ?? '';
  bool get isAuthenticated =>
      uid != null && role != null && active && verified && !loading;
}

abstract class AuthRepository {
  Stream<AuthSession> watch();
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> resetPassword(String email);
  Future<void> sendVerification();
  Future<void> refresh();
  Future<void> completeProfile();
  Future<void> signOut();
}

String authError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'user-disabled' => 'Akun dinonaktifkan. Hubungi pengelola bengkel.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email atau kata sandi salah.',
      'email-already-in-use' =>
        'Email sudah digunakan. Silakan masuk atau reset kata sandi.',
      'weak-password' =>
        'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.',
      'invalid-email' => 'Format email tidak valid.',
      'too-many-requests' => 'Terlalu banyak percobaan. Coba lagi nanti.',
      'network-request-failed' => 'Jaringan terputus. Periksa koneksi Anda.',
      'operation-not-allowed' => 'Login email belum diaktifkan oleh pengelola.',
      _ => 'Autentikasi gagal. Coba lagi.',
    };
  }
  return 'Permintaan gagal. Periksa koneksi dan coba lagi.';
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  @override
  Stream<AuthSession> watch() {
    late StreamController<AuthSession> output;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;
    var generation = 0;
    String? previousUid;
    output = StreamController<AuthSession>(
      onListen: () {
        authSub = auth.idTokenChanges().listen(
          (user) async {
            final current = ++generation;
            await profileSub?.cancel();
            if (current != generation || output.isClosed) return;
            if (user == null) {
              previousUid = null;
              output.add(const AuthSession());
              return;
            }
            if (previousUid != user.uid) {
              output.add(
                AuthSession(uid: user.uid, email: user.email, loading: true),
              );
            }
            previousUid = user.uid;
            profileSub = db
                .collection('users')
                .doc(user.uid)
                .snapshots()
                .listen(
                  (doc) {
                    if (current != generation || output.isClosed) return;
                    final data = doc.data();
                    final roles = UserRole.values.where(
                      (r) => r.name == data?['role'],
                    );
                    output.add(
                      AuthSession(
                        uid: user.uid,
                        email: user.email,
                        role: roles.firstOrNull,
                        verified: user.emailVerified,
                        active: data?['active'] == true,
                        error: !doc.exists
                            ? 'Profil belum tersedia. Lengkapi profil pelanggan.'
                            : null,
                      ),
                    );
                  },
                  onError: (Object e, StackTrace s) {
                    if (current == generation && !output.isClosed) {
                      output.add(
                        AuthSession(
                          uid: user.uid,
                          email: user.email,
                          error:
                              'Profil gagal dimuat. Periksa koneksi dan coba lagi.',
                        ),
                      );
                    }
                  },
                );
          },
          onError: (Object e, StackTrace s) =>
              output.add(AuthSession(error: authError(e))),
        );
      },
      onCancel: () async {
        generation++;
        await authSub?.cancel();
        await profileSub?.cancel();
      },
    );
    return output.stream;
  }

  @override
  Future<void> completeProfile() async {
    final user = auth.currentUser;
    if (user == null) throw StateError('Sesi diperlukan.');
    final profile = db.collection('users').doc(user.uid);
    await db.runTransaction((tx) async {
      final doc = await tx.get(profile);
      if (!doc.exists) {
        tx.set(profile, {
          'email': user.email,
          'role': 'customer',
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await completeProfile();
  }

  @override
  Future<void> register(String email, String password) async {
    await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Retriable on the account screen if either network operation fails.
    await completeProfile();
    await sendVerification();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> sendVerification() async =>
      auth.currentUser?.sendEmailVerification();
  @override
  Future<void> refresh() async {
    try {
      await auth.currentUser?.reload();
      await auth.currentUser?.getIdToken(true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled' ||
          e.code == 'user-token-expired' ||
          e.code == 'user-not-found') {
        await auth.signOut();
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() => auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

class AuthSessionController extends Notifier<AuthSession> {
  @override
  AuthSession build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .watch()
        .listen(
          (session) => state = session,
          onError: (Object e, StackTrace s) =>
              state = AuthSession(error: authError(e)),
        );
    ref.onDispose(subscription.cancel);
    return const AuthSession(loading: true);
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession>(
      AuthSessionController.new,
    );
