import 'package:hive_flutter/hive_flutter.dart';
import 'package:job_finder_app/models/index.dart';

class LocalStorageService {
  static const String _usersBox = 'users';
  static const String _jobsBox = 'jobs';
  static const String _favoritesBox = 'favorites';
  static const String _applicationsBox = 'applications';
  static const String _prefsBox = 'preferences';

  /// Initialize Hive and open boxes
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(JobAdapter());
    Hive.registerAdapter(ApplicationAdapter());

    // Open boxes
    await Hive.openBox<User>(_usersBox);
    await Hive.openBox<Job>(_jobsBox);
    await Hive.openBox<String>(_favoritesBox);
    await Hive.openBox<Application>(_applicationsBox);
    await Hive.openBox<dynamic>(_prefsBox);
  }

  // ============ User Storage ============

  Future<void> saveUser(User user) async {
    final box = Hive.box<User>(_usersBox);
    await box.put('current_user', user);
  }

  User? getUser() {
    final box = Hive.box<User>(_usersBox);
    return box.get('current_user');
  }

  Future<void> clearUser() async {
    final box = Hive.box<User>(_usersBox);
    await box.delete('current_user');
  }

  // ============ Job Storage (Cache) ============

  Future<void> cacheJobs(List<Job> jobs, String category) async {
    final box = Hive.box<Job>(_jobsBox);
    for (final job in jobs) {
      await box.put(job.id, job);
    }
    // Store category timestamp
    final prefs = Hive.box<dynamic>(_prefsBox);
    await prefs.put(
      'jobs_cache_${category}_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<Job> getCachedJobs(String category) {
    final box = Hive.box<Job>(_jobsBox);
    return box.values.where((job) => job.category == category).toList();
  }

  List<Job> getAllCachedJobs() {
    final box = Hive.box<Job>(_jobsBox);
    return box.values.toList();
  }

  Future<void> clearJobsCache() async {
    final box = Hive.box<Job>(_jobsBox);
    await box.clear();
  }

  bool isCacheExpired(String category, {int expiryMinutes = 60}) {
    final prefs = Hive.box<dynamic>(_prefsBox);
    final timestamp = prefs.get('jobs_cache_${category}_time') as int?;
    if (timestamp == null) return true;

    final expiry = Duration(minutes: expiryMinutes);
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp > expiry.inMilliseconds;
  }

  // ============ Favorites ============

  Future<void> addFavorite(String jobId) async {
    final box = Hive.box<String>(_favoritesBox);
    await box.put(jobId, jobId);
  }

  Future<void> removeFavorite(String jobId) async {
    final box = Hive.box<String>(_favoritesBox);
    await box.delete(jobId);
  }

  List<String> getFavorites() {
    final box = Hive.box<String>(_favoritesBox);
    return box.values.toList();
  }

  bool isFavorite(String jobId) {
    final box = Hive.box<String>(_favoritesBox);
    return box.containsKey(jobId);
  }

  Future<void> clearFavorites() async {
    final box = Hive.box<String>(_favoritesBox);
    await box.clear();
  }

  // ============ Applications ============

  Future<void> cacheApplication(Application app) async {
    final box = Hive.box<Application>(_applicationsBox);
    await box.put(app.id, app);
  }

  Application? getApplication(String appId) {
    final box = Hive.box<Application>(_applicationsBox);
    return box.get(appId);
  }

  List<Application> getAllApplications() {
    final box = Hive.box<Application>(_applicationsBox);
    return box.values.toList();
  }

  Future<void> updateApplicationStatus(String appId, String status) async {
    final box = Hive.box<Application>(_applicationsBox);
    final app = box.get(appId);
    if (app != null) {
      app.status = status;
      app.updatedAt = DateTime.now();
      await box.put(appId, app);
    }
  }

  Future<void> clearApplications() async {
    final box = Hive.box<Application>(_applicationsBox);
    await box.clear();
  }

  // ============ Preferences ============

  Future<void> setLastUserId(String uid) async {
    final box = Hive.box<dynamic>(_prefsBox);
    await box.put('last_user_id', uid);
  }

  String? getLastUserId() {
    final box = Hive.box<dynamic>(_prefsBox);
    return box.get('last_user_id') as String?;
  }

  Future<void> setUserType(String userType) async {
    final box = Hive.box<dynamic>(_prefsBox);
    await box.put('user_type', userType);
  }

  String? getUserType() {
    final box = Hive.box<dynamic>(_prefsBox);
    return box.get('user_type') as String?;
  }

  Future<void> clearAll() async {
    await clearUser();
    await clearJobsCache();
    await clearFavorites();
    await clearApplications();
  }
}
