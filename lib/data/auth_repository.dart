import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emits the signed-in user's profile, or null when signed out.
  Stream<AppUser?> userChanges() =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        final profile = await _loadProfile(user.uid);
        if (profile != null) return profile;
        // Registration deletes the account when the profile write fails.
        if (_auth.currentUser?.uid != user.uid) return null;
        await _auth.signOut();
        throw StateError('Profile was not created');
      });

  // shortcut: gives up after ~3s, raise the attempts if profile writes are slower.
  Future<AppUser?> _loadProfile(String uid) async {
    for (var i = 0; i < 10; i++) {
      if (_auth.currentUser?.uid != uid) return null;
      try {
        final doc = await _db.doc('users/$uid').get();
        if (doc.exists) return AppUser.fromMap(uid, doc.data()!);
      } on FirebaseException {
        // The ID token is not always on the first Firestore call after sign-up.
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String department,
    required String location,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final account = cred.user!;
    final user = AppUser(
      uid: account.uid,
      name: name,
      email: email,
      department: department,
      location: location,
    );
    try {
      await account.getIdToken();
      await _db.doc('users/${user.uid}').set(user.toMap());
    } catch (e) {
      try {
        await account.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Staff who can be given an unclaimed report. Admins are not in this list.
  Future<List<AppUser>> listStaff() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: UserRole.staff.name)
        .get();
    return [for (final doc in snap.docs) AppUser.fromMap(doc.id, doc.data())]
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
