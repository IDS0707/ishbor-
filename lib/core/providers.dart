import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_finder_app/services/index.dart';
import 'package:job_finder_app/models/index.dart';

// ============ Firebase Service Provider ============
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// ============ Local Storage Provider ============
final localStorageProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

// ============ Connectivity Provider ============
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService.connectionStream;
});

// ============ Auth Providers ============

final currentUserProvider = StateProvider<User?>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return localStorage.getUser();
});

final authStateProvider = StreamProvider<bool>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.authStateStream;
});

// ============ Job Providers ============

final jobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getAllJobs();
});

final simpleJobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getJobsByCategory('simple_jobs');
});

final officeJobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getJobsByCategory('office_jobs');
});

final onlineJobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getJobsByCategory('online_jobs');
});

final selectedJobProvider = StateProvider<Job?>((ref) {
  return null;
});

final jobDetailsProvider = FutureProvider.family<Job?, String>((
  ref,
  jobId,
) async {
  final firebase = ref.watch(firebaseServiceProvider);
  return firebase.getJob(jobId);
});

// ============ Favorites Providers ============

final favoritesProvider = StateProvider<List<String>>((ref) {
  final localStorage = ref.watch(localStorageProvider);
  return localStorage.getFavorites();
});

final isFavoriteProvider = StateProvider.family<bool, String>((ref, jobId) {
  final localStorage = ref.watch(localStorageProvider);
  return localStorage.isFavorite(jobId);
});

// ============ Applications Providers ============

final userApplicationsProvider = FutureProvider<List<Application>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return firebase.getUserApplications(user.id);
});

// ============ Employer Jobs Provider ============

final employerJobsProvider = FutureProvider<List<Job>>((ref) async {
  final firebase = ref.watch(firebaseServiceProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return firebase.getEmployerJobs(user.id);
});
