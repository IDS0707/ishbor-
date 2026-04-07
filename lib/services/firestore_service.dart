import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../models/worker_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chat models
// ─────────────────────────────────────────────────────────────────────────────

class ChatMsg {
  final String id;
  final String text;
  final String senderUid;
  final DateTime createdAt;

  const ChatMsg({
    required this.id,
    required this.text,
    required this.senderUid,
    required this.createdAt,
  });

  factory ChatMsg.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChatMsg(
      id: doc.id,
      text: d['text'] as String? ?? '',
      senderUid: d['senderUid'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'senderUid': senderUid,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class ChatMeta {
  final String chatId;
  final String jobId;
  final String jobTitle;
  final String posterUid;
  final String seekerUid;
  final String seekerName;
  final String lastMsg;
  final DateTime lastAt;

  const ChatMeta({
    required this.chatId,
    required this.jobId,
    required this.jobTitle,
    required this.posterUid,
    required this.seekerUid,
    required this.seekerName,
    required this.lastMsg,
    required this.lastAt,
  });

  factory ChatMeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChatMeta(
      chatId: doc.id,
      jobId: d['jobId'] as String? ?? '',
      jobTitle: d['jobTitle'] as String? ?? '',
      posterUid: d['posterUid'] as String? ?? '',
      seekerUid: d['seekerUid'] as String? ?? '',
      seekerName: d['seekerName'] as String? ?? '',
      lastMsg: d['lastMsg'] as String? ?? '',
      lastAt: (d['lastAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification model
// ─────────────────────────────────────────────────────────────────────────────

class NotifItem {
  final String id;
  final String type; // 'message' | 'new_job'
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? jobId;
  final String? seekerUid;

  const NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.jobId,
    this.seekerUid,
  });

  factory NotifItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return NotifItem(
      id: doc.id,
      type: d['type'] as String? ?? '',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobId: d['jobId'] as String?,
      seekerUid: d['seekerUid'] as String?,
    );
  }
}

/// Firestore CRUD for the "jobs" collection.
class FirestoreService {
  // Typed collection reference — fromFirestore / toFirestore handled by [Job].
  static final _col =
      FirebaseFirestore.instance.collection('jobs').withConverter<Job>(
            fromFirestore: (snap, _) => Job.fromFirestore(snap),
            toFirestore: (job, _) => job.toFirestore(),
          );

  /// Real-time stream of all jobs, newest first.
  static Stream<List<Job>> jobsStream({int limit = 300}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Real-time stream of jobs for a specific category.
  static Stream<List<Job>> jobsByCategoryStream(String category) {
    return _col
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Real-time stream of jobs filtered by region (slug).
  static Stream<List<Job>> jobsByRegionStream(String region) {
    return _col
        .where('region', isEqualTo: region)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  /// Real-time stream of jobs posted by a specific user.
  static Stream<List<Job>> myJobsStream(String uid) {
    return _col.where('postedByUid', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map((d) => d.data()).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add a new job document. Firestore assigns the id automatically.
  static Future<void> addJob(Job job) => _col.add(job);

  /// Update an existing job by its Firestore document id.
  static Future<void> updateJob(String jobId, Job job) =>
      FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .update(job.toFirestore());

  /// Delete a job by its Firestore document id.
  static Future<void> deleteJob(String jobId) =>
      FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();

  /// Delete a job AND clean up all related chats, messages and notifications.
  static Future<void> deleteJobAndCleanup(
      String jobId, String posterUid) async {
    final db = FirebaseFirestore.instance;

    // 1. Find all chats for this job
    final chatSnap = await _chats.where('jobId', isEqualTo: jobId).get();

    // 2. Collect every UID that should have notifications cleaned up
    final involvedUids = <String>{};
    if (posterUid.isNotEmpty) involvedUids.add(posterUid);
    for (final chatDoc in chatSnap.docs) {
      final data = chatDoc.data();
      final seekerUid = data['seekerUid'] as String? ?? '';
      if (seekerUid.isNotEmpty) involvedUids.add(seekerUid);
    }

    // 3. Delete notifications referencing this job for every involved user
    for (final uid in involvedUids) {
      final notifSnap =
          await _notifs(uid).where('jobId', isEqualTo: jobId).get();
      if (notifSnap.docs.isEmpty) continue;
      final batch = db.batch();
      for (final doc in notifSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // 4. Delete chat messages sub-collection and the chat doc itself
    for (final chatDoc in chatSnap.docs) {
      final msgSnap = await chatDoc.reference.collection('messages').get();
      final batch = db.batch();
      for (final msg in msgSnap.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(chatDoc.reference);
      await batch.commit();
    }

    // 5. Finally delete the job document
    await db.collection('jobs').doc(jobId).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHAT
  // ══════════════════════════════════════════════════════════════════════════

  static final _chats = FirebaseFirestore.instance.collection('chats');

  static String _chatId(String jobId, String seekerUid) =>
      '${jobId}_$seekerUid';

  /// Creates the chat meta document if it doesn't exist yet.
  static Future<void> initChat({
    required String jobId,
    required String jobTitle,
    required String posterUid,
    required String seekerUid,
    required String seekerName,
  }) async {
    final ref = _chats.doc(_chatId(jobId, seekerUid));
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'jobId': jobId,
        'jobTitle': jobTitle,
        'posterUid': posterUid,
        'seekerUid': seekerUid,
        'seekerName': seekerName,
        'lastMsg': '',
        'lastAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Real-time stream of messages for a single chat.
  static Stream<List<ChatMsg>> messagesStream(String jobId, String seekerUid) {
    return _chats
        .doc(_chatId(jobId, seekerUid))
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                ChatMsg.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Send a message and update the chat meta document.
  /// Pass [posterUid], [jobTitle], [senderName] to auto-create a notification
  /// for the recipient.
  static Future<void> sendMessage({
    required String jobId,
    required String seekerUid,
    required String senderUid,
    required String text,
    String posterUid = '',
    String jobTitle = '',
    String senderName = '',
  }) async {
    final chatRef = _chats.doc(_chatId(jobId, seekerUid));
    final msgRef = chatRef.collection('messages').doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(msgRef, {
      'text': text,
      'senderUid': senderUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMsg': text,
      'lastAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    // Push in-app notification to the other participant
    if (posterUid.isNotEmpty) {
      final recipientUid = senderUid == seekerUid ? posterUid : seekerUid;
      if (recipientUid.isNotEmpty) {
        final name = senderName.isEmpty ? '...' : senderName;
        final preview = text.length > 80 ? '${text.substring(0, 80)}…' : text;
        await createNotification(
          uid: recipientUid,
          type: 'message',
          title: jobTitle.isEmpty ? 'Yangi xabar' : jobTitle,
          body: '$name: $preview',
          jobId: jobId,
          seekerUid: seekerUid,
        );
      }
    }
  }

  /// All chats where the current user is the job poster (incoming questions).
  static Stream<List<ChatMeta>> incomingChatsStream(String posterUid) {
    return _chats.where('posterUid', isEqualTo: posterUid).snapshots().map((s) {
      final list = s.docs
          .map((d) =>
              ChatMeta.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      list.sort((a, b) => b.lastAt.compareTo(a.lastAt));
      return list;
    });
  }

  /// All chats where the current user is the seeker (questions they sent).
  static Stream<List<ChatMeta>> myChatsStream(String seekerUid) {
    return _chats.where('seekerUid', isEqualTo: seekerUid).snapshots().map((s) {
      final list = s.docs
          .map((d) =>
              ChatMeta.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
      list.sort((a, b) => b.lastAt.compareTo(a.lastAt));
      return list;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════

  static CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(uid)
          .collection('items');

  /// Real-time stream of the last 50 notifications for [uid], newest first.
  static Stream<List<NotifItem>> notificationsStream(String uid) {
    return _notifs(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) =>
                NotifItem.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  /// Live count of unread notifications for [uid].
  static Stream<int> unreadNotifCount(String uid) {
    return _notifs(uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.size);
  }

  /// Write a new notification document for [uid].
  static Future<void> createNotification({
    required String uid,
    required String type,
    required String title,
    required String body,
    String? jobId,
    String? seekerUid,
  }) async {
    if (uid.isEmpty) return;
    await _notifs(uid).add({
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (jobId != null) 'jobId': jobId,
      if (seekerUid != null) 'seekerUid': seekerUid,
    });
  }

  /// Mark a single notification as read.
  static Future<void> markNotifRead(String uid, String notifId) =>
      _notifs(uid).doc(notifId).update({'isRead': true});

  /// Mark all notifications as read for [uid].
  static Future<void> markAllNotifsRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snaps = await _notifs(uid).where('isRead', isEqualTo: false).get();
    for (final doc in snaps.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUPPORT
  // ══════════════════════════════════════════════════════════════════════════

  /// Save a user-submitted support question.
  static Future<void> createSupportQuestion({
    required String uid,
    required String question,
  }) =>
      FirebaseFirestore.instance.collection('support_questions').add({
        'uid': uid,
        'question': question,
        'createdAt': FieldValue.serverTimestamp(),
        'answered': false,
      });

  // ══════════════════════════════════════════════════════════════════════════
  // WORKER PROFILES
  // ══════════════════════════════════════════════════════════════════════════

  static final _workerProfiles =
      FirebaseFirestore.instance.collection('worker_profiles');

  /// Save (create or overwrite) a worker profile for [uid].
  static Future<void> saveWorkerProfile(WorkerProfile profile) =>
      _workerProfiles.doc(profile.uid).set(
            profile.toFirestore(),
            SetOptions(merge: true),
          );

  /// Fetch a single worker profile for [uid]. Returns null if not found.
  static Future<WorkerProfile?> getWorkerProfile(String uid) async {
    final snap = await _workerProfiles.doc(uid).get();
    if (!snap.exists) return null;
    return WorkerProfile.fromMap(snap.id, snap.data()!);
  }

  /// Real-time stream for one worker profile.
  static Stream<WorkerProfile?> workerProfileStream(String uid) {
    return _workerProfiles.doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return WorkerProfile.fromMap(snap.id, snap.data()!);
    });
  }

  /// Returns worker profiles that have at least one category in [categories]
  /// AND whose age is within [ageMin]..[ageMax] (0 = no limit).
  ///
  /// Firestore does not support array-contains-any combined with range filter
  /// on a different field in a single query, so we fetch by category match
  /// first and filter age client-side.
  static Future<List<WorkerProfile>> matchingWorkers({
    required List<String> categories,
    int ageMin = 0,
    int ageMax = 0,
    String gender = '', // '' = any
  }) async {
    if (categories.isEmpty) return [];

    // array-contains-any supports up to 30 values per query
    final chunks = <List<String>>[];
    for (var i = 0; i < categories.length; i += 30) {
      chunks.add(categories.sublist(
          i, i + 30 > categories.length ? categories.length : i + 30));
    }

    final results = <WorkerProfile>[];
    final seen = <String>{};

    for (final chunk in chunks) {
      final snap = await _workerProfiles
          .where('categories', arrayContainsAny: chunk)
          .get();
      for (final doc in snap.docs) {
        if (seen.contains(doc.id)) continue;
        seen.add(doc.id);
        final profile = WorkerProfile.fromMap(doc.id, doc.data());
        // Client-side age filtering
        if (ageMin > 0 && profile.age < ageMin) continue;
        if (ageMax > 0 && profile.age > ageMax) continue;
        // Client-side gender filtering
        if (gender.isNotEmpty && profile.gender != gender) continue;
        results.add(profile);
      }
    }

    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }
}
