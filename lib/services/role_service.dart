import 'package:shared_preferences/shared_preferences.dart';

/// Stores and retrieves the user's role locally.
/// Roles: 'employer' | 'worker'
class RoleService {
  static const _key = 'user_role';

  static Future<void> setRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clearRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
