import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:job_finder_app/models/index.dart';

class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ Authentication ============

  /// Verify phone number and send OTP
  Future<String> verifyPhoneNumber(String phoneNumber) async {
    String? verificationId;

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted:
          (firebase_auth.PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (firebase_auth.FirebaseAuthException e) {
        throw Exception('Phone verification failed: ${e.message}');
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );

    if (verificationId == null) {
      throw Exception('Failed to send OTP');
    }
    return verificationId!;
  }

  /// Verify OTP and sign in
  Future<firebase_auth.UserCredential> verifyOTP(
      String verificationId, String otp) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message}');
    }
  }

  /// Stream of auth state changes (true = signed in)
  Stream<bool> get authStateStream =>
      _auth.authStateChanges().map((u) => u != null);

  /// Get current Firebase user
  firebase_auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if user exists in Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ============ User Management ============

  /// Create or update user
  Future<void> saveUser(String uid, User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  /// Get user by UID
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromJson({'id': uid, ...doc.data()!});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // ============ Job Management ============

  /// Create a new job
  Future<String> createJob(Job job) async {
    try {
      final docRef = await _firestore.collection('jobs').add(job.toJson());
      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  /// Get all jobs
  Future<List<Job>> getAllJobs() async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) => Job.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  /// Get jobs by category
  Future<List<Job>> getJobsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      return snapshot.docs
          .map((doc) => Job.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs by category: $e');
    }
  }

  /// Get jobs posted by employer
  Future<List<Job>> getEmployerJobs(String employerId) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Job.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch employer jobs: $e');
    }
  }

  /// Get job by ID
  Future<Job?> getJob(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        return Job.fromJson({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get job: $e');
    }
  }

  /// Update job view count
  Future<void> incrementJobViews(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silent fail for tracking
    }
  }

  // ============ Application Management ============

  /// Apply for a job
  Future<String> applyForJob(Application application) async {
    try {
      final docRef =
          await _firestore.collection('applications').add(application.toJson());
      await docRef.update({'id': docRef.id});

      // Increment job contacts count
      await _firestore.collection('jobs').doc(application.jobId).update({
        'contactsCount': FieldValue.increment(1),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to apply for job: $e');
    }
  }

  /// Get applications for a job seeker
  Future<List<Application>> getUserApplications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Application.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user applications: $e');
    }
  }

  /// Update application status
  Future<void> updateApplicationStatus(String appId, String status) async {
    try {
      await _firestore.collection('applications').doc(appId).update({
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }
}
