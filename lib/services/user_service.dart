import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Manages the "users" collection in Firestore.
///
/// Called after every successful authentication to ensure the user
/// document exists (creates on first sign-in, skips if already present).
class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Creates or updates the user document in Firestore.
  ///
  /// Uses [SetOptions(merge: true)] so repeated calls never overwrite
  /// existing fields (e.g. a createdAt set on first sign-in).
  static Future<void> saveUser(
    User user, {
    String? displayName,
    String? phoneNumber,
  }) async {
    final data = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'phone': phoneNumber ?? user.phoneNumber,
      'displayName': displayName ?? user.displayName ?? '',
      'photoUrl': user.photoURL,
      'lastSignIn': FieldValue.serverTimestamp(),
    };

    // Only set createdAt if the document doesn't exist yet.
    await _users.doc(user.uid).set(
      {...data, 'createdAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Returns true if a document for [uid] already exists.
  static Future<bool> userExists(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists;
  }

  /// Fetch the user document for [uid].  Returns null if not found.
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.exists ? snap.data() : null;
  }
}
