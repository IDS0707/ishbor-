import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves the user's role locally AND in Firestore.
/// Roles: 'employer' | 'worker'
class RoleService {
  static const _key = 'user_role';
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Saves the role to SharedPreferences (fast) and Firestore (persistent
  /// across devices / reinstalls).
  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role);
    final uid = _uid;
    if (uid != null) {
      await _db
          .collection('users')
          .doc(uid)
          .set({'role': role}, SetOptions(merge: true));
    }
  }

  /// Returns the role. Always fetches from Firestore so cross-device changes
  /// (e.g. changing role on another device) are picked up immediately.
  /// Falls back to local cache only if Firestore is unreachable.
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;

    if (uid != null) {
      try {
        final doc = await _db.collection('users').doc(uid).get();
        final remote = doc.data()?['role'] as String?;
        if (remote != null && remote.isNotEmpty) {
          // Sync local cache with Firestore value
          await prefs.setString(_key, remote);
          return remote;
        }
        // Firestore reachable but no role → yangi foydalanuvchi,
        // eski cache ni o'chirib null qaytaramiz
        await prefs.remove(_key);
        return null;
      } catch (_) {
        // Firestore unreachable — fall through to local cache
      }
    }

    // Fallback: local cache (offline / no uid)
    return prefs.getString(_key);
  }

  /// Clears local cache only (used when the user explicitly switches role).
  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
