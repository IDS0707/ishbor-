import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Handles user-submitted job reports and user blocks.
class ReportService {
  static final _db = FirebaseFirestore.instance;

  // ── Reports ────────────────────────────────────────────────────────────────

  /// Submit a report for a job listing.
  ///
  /// [jobId]       — the Firestore document ID of the job.
  /// [reason]      — one of: 'spam', 'fake', 'offensive', 'other'.
  /// [reporterUid] — UID of the user submitting the report (must be authenticated).
  static Future<void> reportJob({
    required String jobId,
    required String reason,
    required String reporterUid,
    String posterUid = '',
  }) async {
    if (reporterUid.isEmpty || jobId.isEmpty) return;

    // Prevent duplicate reports from the same user for the same job.
    final existing = await _db
        .collection('reports')
        .where('jobId', isEqualTo: jobId)
        .where('reporterUid', isEqualTo: reporterUid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // already reported

    await _db.collection('reports').add({
      'jobId': jobId,
      'posterUid': posterUid,
      'reporterUid': reporterUid,
      'reason': reason,
      'status': 'pending', // pending | reviewed | dismissed
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment a denormalised counter on the job so moderation dashboards
    // can surface frequently-reported listings without an extra aggregation.
    await _db.collection('jobs').doc(jobId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ── Blocks ─────────────────────────────────────────────────────────────────

  /// Block [targetUid] for the current user [blockerUid].
  /// Stores the block in `blocks/{blockerUid}/blocked/{targetUid}`.
  static Future<void> blockUser({
    required String blockerUid,
    required String targetUid,
  }) async {
    if (blockerUid.isEmpty || targetUid.isEmpty) return;
    await _db
        .collection('blocks')
        .doc(blockerUid)
        .collection('blocked')
        .doc(targetUid)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  /// Returns true if [blockerUid] has blocked [targetUid].
  static Future<bool> isBlocked({
    required String blockerUid,
    required String targetUid,
  }) async {
    if (blockerUid.isEmpty || targetUid.isEmpty) return false;
    final doc = await _db
        .collection('blocks')
        .doc(blockerUid)
        .collection('blocked')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  /// Unblock [targetUid] for [blockerUid].
  static Future<void> unblockUser({
    required String blockerUid,
    required String targetUid,
  }) async {
    if (blockerUid.isEmpty || targetUid.isEmpty) return;
    await _db
        .collection('blocks')
        .doc(blockerUid)
        .collection('blocked')
        .doc(targetUid)
        .delete();
  }

  /// Convenience: report using the currently signed-in user.
  static Future<void> reportJobAsCurrentUser({
    required String jobId,
    required String reason,
    String posterUid = '',
  }) {
    final uid = AuthService.currentUser?.uid ?? '';
    return reportJob(
      jobId: jobId,
      reason: reason,
      reporterUid: uid,
      posterUid: posterUid,
    );
  }

  /// Convenience: block using the currently signed-in user.
  static Future<void> blockUserAsCurrentUser(String targetUid) {
    final uid = AuthService.currentUser?.uid ?? '';
    return blockUser(blockerUid: uid, targetUid: targetUid);
  }
}
