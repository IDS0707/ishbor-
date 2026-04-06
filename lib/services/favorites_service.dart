import 'package:shared_preferences/shared_preferences.dart';

/// Persists saved job IDs to [SharedPreferences].
class FavoritesService {
  static const _key = 'saved_jobs';

  /// Returns the current set of saved job IDs.
  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  /// Adds [jobId] if not saved, removes it if already saved.
  static Future<void> toggle(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? []).toSet();
    if (ids.contains(jobId)) {
      ids.remove(jobId);
    } else {
      ids.add(jobId);
    }
    await prefs.setStringList(_key, ids.toList());
  }

  static Future<bool> isFavorite(String jobId) async =>
      (await load()).contains(jobId);
}
